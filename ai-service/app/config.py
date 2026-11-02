"""Konfigurasi layanan AI (dibaca dari environment)."""
import os
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent
DATA_DIR = BASE_DIR / "data"
MODELS_DIR = BASE_DIR / "models"

MODEL_PATH = Path(os.getenv("FOOD_MODEL_PATH", MODELS_DIR / "food_model.h5"))
LABELS_PATH = MODELS_DIR / "class_labels.json"
MAX_IMAGE_BYTES = int(os.getenv("MAX_IMAGE_BYTES", 5 * 1024 * 1024))
# Isi jika ingin chatbot memakai LLM sungguhan (belum dipakai pada versi stub).
LLM_API_KEY = os.getenv("LLM_API_KEY", "")
