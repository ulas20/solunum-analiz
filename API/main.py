"""
SolunumAI — Respiratory Disease Detection API
FastAPI backend: YAMNet audio embeddings + XGBoost models
"""

from __future__ import annotations

import io
import json
import logging
import os
import pickle
import tempfile
import traceback
from pathlib import Path
from typing import Optional

import joblib
try:
    import dill
except ImportError:
    dill = None

import librosa
import numpy as np
import soundfile as sf
from fastapi import FastAPI, File, Form, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------
logging.basicConfig(level=logging.INFO, format="%(asctime)s | %(levelname)s | %(message)s")
log = logging.getLogger("solunumai")

# ---------------------------------------------------------------------------
# App
# ---------------------------------------------------------------------------
app = FastAPI(
    title="SolunumAI API",
    description="Respiratory disease detection using ML models trained on cough sounds.",
    version="2.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
MODELS_DIR = Path(__file__).parent / "models"
SAMPLE_RATE = 16_000
MIN_DURATION = 2.0
MAX_DURATION = 10.0
SILENCE_THRESHOLD = 0.001

# ---------------------------------------------------------------------------
# Model registry
# ---------------------------------------------------------------------------
_models: dict = {}


def _load_pkl(filename: str):
    path = MODELS_DIR / filename
    if not path.exists():
        log.warning("Model file not found: %s", path)
        return None
    loaders = [
        ("pickle", lambda p: pickle.load(open(p, "rb"))),
        ("joblib", lambda p: joblib.load(str(p))),
    ]
    if dill:
        loaders.append(("dill", lambda p: dill.load(open(p, "rb"))))
    for name, loader in loaders:
        try:
            obj = loader(path)
            log.info("Loaded %s with %s → %s", filename, name, type(obj).__name__)
            return obj
        except Exception:
            continue
    log.error("All loaders failed: %s", filename)
    return None


@app.on_event("startup")
async def load_models():
    log.info("Loading ML models from %s ...", MODELS_DIR)

    # Primary: simple COVID model (audio-only, 1024-dim)
    _models["model_covid"]  = _load_pkl("model_covid_clean.pkl")

    # Fallback stacking models (v6) if model_covid_clean.pkl not present
    if _models["model_covid"] is None:
        log.warning("model_covid_clean.pkl not found — falling back to v6 stacking pipeline")
        _models["model_a"]       = _load_pkl("model_lr_a_v6.pkl")
        _models["model_b"]       = _load_pkl("model_lr_b_v6.pkl")
        _models["calibrator_a"]  = _load_pkl("calibrator_a_v6.pkl")
        _models["calibrator_b"]  = _load_pkl("calibrator_b_v6.pkl")
        _models["meta_lr"]       = _load_pkl("meta_lr_v6.pkl")
        _models["scaler_covid"]  = _load_pkl("scaler_covid_meta_v6.pkl")

    # AIRS model (shared)
    _models["model_airs"]   = _load_pkl("model_airs_full.pkl")
    _models["scaler_airs"]  = _load_pkl("scaler_airs.pkl")

    # YAMNet
    try:
        import tensorflow_hub as hub
        log.info("Loading YAMNet from TensorFlow Hub...")
        _models["yamnet"] = hub.load("https://tfhub.dev/google/yamnet/1")
        log.info("YAMNet loaded successfully.")
    except Exception as exc:
        log.warning("YAMNet not available (%s). Demo mode active.", exc)
        _models["yamnet"] = None

    loaded = [k for k, v in _models.items() if v is not None]
    log.info("Loaded models: %s", loaded)


# ---------------------------------------------------------------------------
# Audio utilities
# ---------------------------------------------------------------------------

def _bytes_to_wav_array(audio_bytes: bytes, filename: str) -> tuple[np.ndarray, float]:
    """Load audio bytes → mono float32 at 16 kHz, PCM-16 quantized (matches training pipeline)."""
    with tempfile.NamedTemporaryFile(suffix=Path(filename).suffix or ".wav", delete=False) as tmp:
        tmp.write(audio_bytes)
        tmp_path = tmp.name

    pcm_path = tmp_path + "_pcm16.wav"
    try:
        y, _ = librosa.load(tmp_path, sr=SAMPLE_RATE, mono=True)
        sf.write(pcm_path, y, SAMPLE_RATE, subtype="PCM_16")
        y, _ = librosa.load(pcm_path, sr=SAMPLE_RATE, mono=True)
    finally:
        os.unlink(tmp_path)
        if os.path.exists(pcm_path):
            os.unlink(pcm_path)

    return y, len(y) / SAMPLE_RATE


def _trim_to_max(y: np.ndarray) -> np.ndarray:
    """Ses MAX_DURATION'dan uzunsa ilk MAX_DURATION saniyeyi kullan."""
    max_samples = int(MAX_DURATION * SAMPLE_RATE)
    return y[:max_samples] if len(y) > max_samples else y


def _validate_audio(y: np.ndarray, duration: float) -> Optional[str]:
    if duration < MIN_DURATION:
        return f"Ses kaydı çok kısa ({duration:.1f} sn). En az {MIN_DURATION:.0f} saniye öksürün."
    if float(np.abs(y).mean()) < SILENCE_THRESHOLD:
        return "Ses kaydı çok sessiz. Mikrofona daha yakın konumlanın ve tekrar deneyin."
    return None


def _extract_yamnet_embedding(y: np.ndarray) -> np.ndarray:
    """1024-dim YAMNet embedding (mean over frames)."""
    yamnet = _models.get("yamnet")
    if yamnet is None:
        rng = np.random.default_rng(int(np.abs(y).mean() * 1e6) % (2**31))
        return rng.random(1024).astype(np.float32)

    import tensorflow as tf
    waveform = tf.constant(y, dtype=tf.float32)
    _, embeddings, _ = yamnet(waveform)
    return tf.reduce_mean(embeddings, axis=0).numpy().astype(np.float32)


# ---------------------------------------------------------------------------
# Inference
# ---------------------------------------------------------------------------

def _predict_p1(embedding: np.ndarray, clinical_b: Optional[np.ndarray] = None) -> float:
    """COVID/gribal probability (p1).

    Primary path: model_covid_clean (audio-only, 1024-dim).
    Fallback: v6 stacking pipeline if model_covid_clean not available.
    """
    model_covid = _models.get("model_covid")

    if model_covid is not None:
        p1 = float(model_covid.predict_proba(embedding.reshape(1, -1))[0][1])
        return float(np.clip(p1, 0.0, 1.0))

    # v6 stacking fallback
    model_a      = _models.get("model_a")
    model_b      = _models.get("model_b")
    cal_a        = _models.get("calibrator_a")
    cal_b        = _models.get("calibrator_b")
    meta_lr      = _models.get("meta_lr")
    scaler_covid = _models.get("scaler_covid")

    if any(m is None for m in [model_a, model_b, cal_a, cal_b, meta_lr]):
        rng = np.random.default_rng(int(embedding.mean() * 1e6) % (2**31))
        return float(rng.random())

    feat_a = embedding.reshape(1, -1)
    raw_a  = model_a.predict_proba(feat_a)[0, 1]
    p_a    = float(cal_a.predict_proba([[raw_a]])[0, 1])

    clin_sc = scaler_covid.transform(clinical_b.reshape(1, -1))[0] if scaler_covid is not None else clinical_b
    feat_b  = np.concatenate([embedding, clin_sc]).reshape(1, -1)
    raw_b   = model_b.predict_proba(feat_b)[0, 1]
    p_b     = float(cal_b.predict_proba([[raw_b]])[0, 1])

    p1 = float(meta_lr.predict_proba([[p_a, p_b]])[0, 1])
    return float(np.clip(p1, 0.0, 1.0))


def _predict_p2_airs(embedding: np.ndarray, clinical_airs: np.ndarray) -> tuple[float, int, str]:
    """AIRS: Astım/KOAH probability (p2), class index, class name.
    clinical_airs: 9 features — [yas, cinsiyet, wheeze_gecmis, balgam, ates,
                                   sigara_binary, aile_astim, tb_temas, pack_years]
    """
    model_airs  = _models.get("model_airs")
    scaler_airs = _models.get("scaler_airs")

    if model_airs is None:
        rng  = np.random.default_rng(int(embedding[:512].mean() * 1e8) % (2**31))
        p2   = float(rng.random())
        pred = int(rng.integers(0, 3))
        return np.clip(p2, 0.0, 1.0), pred, {0: "Sağlıklı", 1: "Astım", 2: "KOAH"}[pred]

    clin_sc = scaler_airs.transform(clinical_airs.reshape(1, -1))[0] if scaler_airs is not None else clinical_airs
    feat    = np.concatenate([embedding[:512], clin_sc]).reshape(1, -1)
    proba   = model_airs.predict_proba(feat)[0]
    pred    = int(np.argmax(proba))
    p2      = float(proba[1] + proba[2]) if len(proba) > 2 else float(proba[pred])
    names   = {0: "Sağlıklı", 1: "Astım", 2: "KOAH"}
    return float(np.clip(p2, 0.0, 1.0)), pred, names.get(pred, "Bilinmiyor")


def _build_clinical_vector_airs(meta: dict) -> np.ndarray:
    """9 klinik özellik — AIRS için.
    Sıra: yas, cinsiyet, wheeze_gecmis, balgam, ates,
          sigara_binary, aile_astim, tb_temas, pack_years
    """
    pack_years = float(meta.get("pack_years", 0))
    return np.array([
        float(meta["yas"]),
        float(meta["cinsiyet"]),                      # 0=Kadın, 1=Erkek
        float(int(meta.get("wheeze_gecmis", False))),
        float(int(meta.get("balgam", False))),
        float(int(meta.get("ates", False))),
        1.0 if pack_years > 0 else 0.0,              # sigara_binary
        float(int(meta.get("aile_astim", False))),
        float(int(meta.get("tb_temas", False))),
        pack_years,
    ], dtype=np.float32)


def _build_clinical_vector_b(meta: dict) -> np.ndarray:
    """5 klinik özellik — v6 stacking Model B için (fallback only)."""
    yas = int(meta["yas"])
    def yas_grubu(y):
        if y < 18: return 0
        if y < 36: return 1
        if y < 60: return 2
        return 3
    return np.array([
        float(yas),
        float(meta["cinsiyet"]),
        float(int(meta.get("ates", False))),
        0.0,  # solunum_sorunu (removed from new spec)
        float(yas_grubu(yas)),
    ], dtype=np.float32)


def _make_decision(p1: float, p2: float, p_final: float, airs_pred: int, airs_isim: str) -> tuple[str, str, str, str]:
    """Return (genel, alt_karar, oneri).

    Öncelik sırası:
      1. COVID yüksek (p1 >= 0.55)
      2. KOAH güçlü (p2 >= 0.65)
      3. Astım güçlü (p2 >= 0.65)
      4. COVID orta (p1 >= 0.35)
      5. AIRS orta
      6. Genel şüphe
      7. Temiz
    """
    if p1 >= 0.38:
        alt_karar = "COVID-19 / viral solunum yolu enfeksiyonu şüphesi"
        oneri     = "PCR veya antijen testi yaptırın, kalabalık ortamlardan uzak durun. Ateş veya nefes darlığı varsa doktora başvurun."
    elif airs_pred == 2 and p2 >= 0.55:
        alt_karar = "KOAH şüphesi"
        oneri     = "Göğüs hastalıkları uzmanına başvurun. Sigara bırakmanız kritik."
    elif airs_pred == 1 and p2 >= 0.55:
        alt_karar = "Astım şüphesi"
        oneri     = "Göğüs hastalıkları uzmanına başvurun. Solunum fonksiyon testi yaptırın."
    elif p1 >= 0.22:
        alt_karar = "Viral solunum yolu rahatsızlığı şüphesi (COVID-19 dahil)"
        oneri     = "Bol sıvı tüketin, dinlenin. Belirtiler kötüleşirse veya ateş 38.5°C'yi geçerse doktora gidin."
    elif airs_pred in (1, 2):
        alt_karar = f"{airs_isim} şüphesi (orta olasılık)"
        oneri     = "Belirtiler devam ederse göğüs hastalıkları uzmanına başvurun."
    elif p_final >= 0.28:
        alt_karar = "Genel solunum yolu şüphesi"
        oneri     = "Belirtiler 1 haftadan uzun sürerse doktora başvurun."
    else:
        alt_karar = "Belirgin bulgu yok"
        oneri     = "Öksürük 2 haftadan uzun sürerse doktora başvurun."

    p_dominant = max(p1, p_final)
    if p1 >= 0.38:
        genel = "COVID-19 / viral enfeksiyon riski tespit edildi"
    elif p_dominant >= 0.35:
        genel = "Solunum yolu rahatsızlığı tespit edildi"
    elif p_dominant >= 0.22:
        genel = "Solunum yolu rahatsızlığı şüphesi"
    else:
        genel = "Belirgin solunum rahatsızlığı tespit edilmedi"

    return genel, alt_karar, oneri


# ---------------------------------------------------------------------------
# Response schema
# ---------------------------------------------------------------------------

class AnalysisResponse(BaseModel):
    p1:             float = Field(..., description="Gribal/COVID olasılığı (0-1)")
    p2:             float = Field(..., description="Astım/KOAH olasılığı (0-1)")
    p_final:        float = Field(..., description="Ağırlıklı birleşik skor (0-1)")
    p_final_yuzde:  float = Field(..., description="P_final yüzde olarak")
    airs_pred:      int
    airs_isim:      str
    genel:          str
    alt_karar:      str
    oneri:          str


# ---------------------------------------------------------------------------
# Endpoints
# ---------------------------------------------------------------------------

@app.get("/health", tags=["System"])
async def health():
    loaded = [k for k, v in _models.items() if v is not None]
    return {"durum": "aktif", "yuklenen_modeller": loaded, "versiyon": "2.0.0"}


@app.post("/analyze", response_model=AnalysisResponse, tags=["Analiz"])
async def analyze(
    audio:    UploadFile = File(..., description="WAV / M4A ses dosyası"),
    metadata: str        = Form(..., description="JSON string: yas, cinsiyet(0/1), wheeze_gecmis, balgam, ates, aile_astim, tb_temas, sigara, pack_years"),
):
    # 1. Parse metadata JSON
    try:
        meta = json.loads(metadata)
    except json.JSONDecodeError as exc:
        raise HTTPException(status_code=422, detail=f"metadata JSON geçersiz: {exc}")

    # 2. Validate required fields
    try:
        yas      = int(meta["yas"])
        cinsiyet = int(meta["cinsiyet"])  # 0=Kadın, 1=Erkek
    except (KeyError, ValueError) as exc:
        raise HTTPException(status_code=422, detail=f"Eksik veya geçersiz metadata alanı: {exc}")

    if not (0 <= yas <= 120):
        raise HTTPException(status_code=422, detail="Geçersiz yaş değeri (0-120).")
    if cinsiyet not in (0, 1):
        raise HTTPException(status_code=422, detail="cinsiyet 0 (Kadın) veya 1 (Erkek) olmalıdır.")

    meta["yas"]      = yas
    meta["cinsiyet"] = cinsiyet

    # 3. Read & validate audio
    try:
        audio_bytes = await audio.read()
    except Exception as exc:
        raise HTTPException(status_code=400, detail=f"Ses dosyası okunamadı: {exc}")

    if not audio_bytes:
        raise HTTPException(status_code=400, detail="Boş ses dosyası gönderildi.")

    log.info(">>> Gelen ses: filename=%s size=%d bytes content_type=%s",
             audio.filename, len(audio_bytes), audio.content_type)

    try:
        y, duration = _bytes_to_wav_array(audio_bytes, audio.filename or "audio.wav")
    except Exception:
        log.error("Audio decode error: %s", traceback.format_exc())
        raise HTTPException(status_code=422, detail="Ses dosyası çözümlenemedi. WAV veya M4A formatında gönderin.")

    log.info(">>> Ses decode OK: duration=%.2fs samples=%d rms=%.5f", duration, len(y), float(np.abs(y).mean()))

    err = _validate_audio(y, duration)
    if err:
        raise HTTPException(status_code=422, detail=err)

    # Trim to max duration if needed
    y = _trim_to_max(y)

    # 4. Feature extraction
    try:
        embedding     = _extract_yamnet_embedding(y)
        clinical_airs = _build_clinical_vector_airs(meta)
        clinical_b    = _build_clinical_vector_b(meta)   # only used in v6 fallback
    except Exception:
        log.error("Feature extraction failed: %s", traceback.format_exc())
        raise HTTPException(status_code=500, detail="Ses özellik çıkarımı sırasında hata oluştu.")

    # 5. Inference
    try:
        p1                       = _predict_p1(embedding, clinical_b)
        p2, airs_pred, airs_isim = _predict_p2_airs(embedding, clinical_airs)
        p_final                  = float(np.clip(0.55 * p1 + 0.45 * p2, 0.0, 1.0))
        genel, alt_karar, oneri  = _make_decision(p1, p2, p_final, airs_pred, airs_isim)
    except Exception:
        log.error("Inference failed: %s", traceback.format_exc())
        raise HTTPException(status_code=500, detail="Model tahmini sırasında hata oluştu.")

    log.info(">>> Sonuç — p1=%.4f p2=%.4f p_final=%.4f airs=%s genel=%s", p1, p2, p_final, airs_isim, genel)
    print(f"p1: {p1:.3f}")
    print(f"p2: {p2:.3f}")
    print(f"p_final: {p_final:.3f}")
    print(f"airs_pred: {airs_pred}")

    return AnalysisResponse(
        p1            = round(p1, 3),
        p2            = round(p2, 3),
        p_final       = round(p_final, 3),
        p_final_yuzde = round(p_final * 100, 1),
        airs_pred     = airs_pred,
        airs_isim     = airs_isim,
        genel         = genel,
        alt_karar     = alt_karar,
        oneri         = oneri,
    )


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------
if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
