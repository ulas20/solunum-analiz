# SolunumAI 🫁

**Yapay Zeka Destekli Solunum Hastalığı Tarama Uygulaması**

Öksürük sesi analizi ile COVID-19, Astım ve KOAH risk taraması yapan iOS uygulaması + FastAPI backend.

---

## Mimari

```
SolunumAI/
├── API/                          # FastAPI Python Backend
│   ├── main.py                   # Ana uygulama + ML pipeline
│   ├── requirements.txt
│   ├── Dockerfile
│   └── models/                   # .pkl model dosyaları buraya
│
├── SolunumAI/                    # iOS SwiftUI Uygulaması
│   ├── App/
│   │   └── SolunumAIApp.swift    # @main + TabView
│   ├── Views/
│   │   ├── HomeView.swift        # Tab 1 — Ana Sayfa
│   │   ├── AnalysisView.swift    # Tab 2 — 3 adım analiz sihirbazı
│   │   ├── HistoryView.swift     # Tab 3 — Geçmiş + Charts
│   │   └── ExercisesView.swift   # Tab 4 — Nefes egzersizleri
│   ├── Components/
│   │   ├── RiskGaugeView.swift   # Animasyonlu dairesel gösterge
│   │   ├── AudioWaveformView.swift
│   │   ├── BreathingAnimationView.swift
│   │   └── HealthTipCardView.swift
│   ├── Models/
│   │   ├── AnalysisResult.swift  # API request/response modelleri
│   │   └── SolunumAI.xcdatamodeld/
│   ├── Services/
│   │   ├── APIService.swift      # URLSession async/await
│   │   ├── AudioRecorderService.swift
│   │   └── CoreDataService.swift
│   └── Resources/
│       ├── Assets.xcassets/      # Renk paleti
│       └── Info.plist
│
├── project.yml                   # xcodegen yapılandırması
├── setup.sh                      # Tek komut kurulum
└── README.md
```

---

## Hızlı Başlangıç

### 1. Kurulum

```bash
cd SolunumAI
./setup.sh
```

Bu script:
- `xcodegen` ile Xcode projesi oluşturur
- Python sanal ortamı kurar ve bağımlılıkları yükler

### 2. ML Modellerini Kopyalayın

`API/models/` dizinine aşağıdaki dosyaları koyun:

| Dosya | Açıklama |
|-------|----------|
| `model_lr_a_v6.pkl` | XGBoost Model A (ses only) |
| `model_lr_b_v6.pkl` | XGBoost Model B (ses + klinik) |
| `calibrator_a_v6.pkl` | Platt scaler A |
| `calibrator_b_v6.pkl` | Platt scaler B |
| `meta_lr_v6.pkl` | LR meta stacking modeli |
| `model_airs_full.pkl` | AIRS Astım/KOAH modeli |
| `scaler_covid_meta_v6.pkl` | COVID meta scaler |
| `scaler_airs.pkl` | AIRS scaler |

> **Demo Modu:** Modeller eksikse API rastgele tahminle çalışır — geliştirme için uygundur.

### 3. API'yi Başlatın

```bash
cd API
source .venv/bin/activate
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

API Dokümantasyonu: [http://localhost:8000/docs](http://localhost:8000/docs)

### 4. iOS Uygulamasını Açın

```bash
open SolunumAI.xcodeproj
```

Xcode'da:
- Target: `SolunumAI`
- Simulator veya gerçek cihaz seçin (mikrofon için gerçek cihaz önerilir)
- ▶ ile çalıştırın

---

## API Referansı

### `POST /analyze`

**Form Data:**

| Alan | Tip | Açıklama |
|------|-----|----------|
| `audio` | File | WAV / M4A / MP3 (2-10 sn) |
| `yas` | int | Yaş |
| `cinsiyet` | string | "Erkek" veya "Kadın" |
| `ates` | bool | Ateş var mı? |
| `solunum_sorunu` | bool | Solunum sorunu var mı? |
| `sigara` | bool | Sigara kullanıyor mu? |
| `hipertansiyon` | bool | Hipertansiyon var mı? |
| `wheeze_gecmis` | bool | Hırıltılı solunum geçmişi? |
| `balgam` | bool | Balgamlı öksürük? |
| `aile_astim` | bool | Ailede astım? |
| `tb_temas` | bool | TB teması? |
| `pack_years` | int | Sigara paket-yıl |

**Yanıt:**

```json
{
  "p1": 0.342,
  "p2": 0.187,
  "p_final": 0.252,
  "airs_pred": 0,
  "airs_isim": "Sağlıklı",
  "karar": "Düşük Risk",
  "alt_karar": "Belirtileriniz ciddi bir solunum hastalığına işaret etmiyor.",
  "oneri": "Sağlıklı yaşam alışkanlıklarınızı sürdürün..."
}
```

### Risk Skorlama

| P_Final | Risk Seviyesi | Renk |
|---------|---------------|------|
| < 0.40 | Düşük Risk | Yeşil |
| 0.40 – 0.50 | Orta Risk | Turuncu |
| ≥ 0.50 | Yüksek Risk | Kırmızı |

### ML Pipeline

```
Ses (WAV/M4A)
    └─► librosa (16kHz, mono)
    └─► YAMNet (1024-dim embedding)
         ├─► Model A (ses) → Calibrator A → p_a
         ├─► Model B (ses+klinik) → Calibrator B → p_b
         └─► Meta LR (p_a, p_b) → p1 (COVID/gribal)
         └─► AIRS model (512-dim) → p2 (Astım/KOAH)

p_final = 0.417 × p1 + 0.583 × p2
```

---

## Docker ile Deployment

```bash
cd API
docker build -t solunumai-api .
docker run -p 8000:8000 -v $(pwd)/models:/app/models solunumai-api
```

---

## iOS Uygulama Özellikleri

### Tab 1 — Ana Sayfa
- Hero banner + hızlı analiz butonu
- İstatistik kartları (toplam analiz, gün serisi)
- 6 sağlık ipucu kartı (yatay kaydırma, genişletilebilir)

### Tab 2 — Analiz (3 adım)
1. **Ses Kaydı** — Gerçek zamanlı dalga formu, seviye göstergesi, 2-10 sn doğrulama
2. **Belirtiler** — Yaş/cinsiyet, 8 semptom toggle, pack-years slider
3. **Sonuç** — Animasyonlu gauge, model detay çubukları, öneri kartı, kaydet butonu

### Tab 3 — Geçmiş
- Trend grafiği (son 30 analiz, SwiftUI Charts)
- Filtreler: Tümü / Yüksek Risk / Düşük Risk
- Tarih araması, genişletilebilir satırlar
- Sola kaydırarak silme, CSV dışa aktarma
- CoreData ile kalıcı depolama

### Tab 4 — Egzersizler
- 5 nefes egzersizi: Diyafram, 4-7-8, Büzük Dudak, Kutu Nefesi, Kontrollü Öksürük
- Animasyonlu görsel rehberler (genişleyen daire, kayan kutu)
- Kronometre, duraklat/devam, seans sayacı
- Haptic feedback, tamamlama kutlaması

---

## Teknik Gereksinimler

- **iOS 16+**
- **Xcode 15+**
- **Swift 5.9+**
- **Python 3.11+** (backend için)

---

## Önemli Uyarı

> Bu uygulama tıbbi tanı koyamaz. Sonuçlar yalnızca bilgilendirme amaçlıdır.
> Kesin tanı için mutlaka bir göğüs hastalıkları uzmanına başvurun.
