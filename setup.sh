#!/usr/bin/env bash
set -e

echo "🫁  SolunumAI Proje Kurulum Scripti"
echo "======================================"

# ── Xcode project ──────────────────────────────────────────────────────────
echo "🔨 Xcode projesi oluşturuluyor..."
python3 generate_xcodeproj.py

echo "✅ SolunumAI.xcodeproj oluşturuldu!"
echo ""

# ── Backend API ─────────────────────────────────────────────────────────────
echo "🐍 FastAPI backend kurulumu..."

cd API

if ! command -v python3 &>/dev/null; then
  echo "❌ Python 3 gerekli: https://python.org"
  exit 1
fi

if [ ! -d ".venv" ]; then
  python3 -m venv .venv
fi

source .venv/bin/activate
pip install --upgrade pip -q
pip install -r requirements.txt -q

echo "✅ Python bağımlılıkları kuruldu!"
echo ""
echo "📁 ML Model Dosyaları"
echo "  Aşağıdaki .pkl dosyalarını API/models/ dizinine kopyalayın:"
echo "    model_lr_a_v6.pkl"
echo "    model_lr_b_v6.pkl"
echo "    calibrator_a_v6.pkl"
echo "    calibrator_b_v6.pkl"
echo "    meta_lr_v6.pkl"
echo "    model_airs_full.pkl"
echo "    scaler_covid_meta_v6.pkl"
echo "    scaler_airs.pkl"
echo ""
echo "🚀 API'yi başlatmak için:"
echo "   cd API && source .venv/bin/activate && uvicorn main:app --reload"
echo ""
echo "📱 iOS uygulamasını açmak için:"
echo "   open SolunumAI.xcodeproj"
