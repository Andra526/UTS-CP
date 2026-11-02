"""Memuat model deteksi makanan.

SAAT INI selalu memakai StubModel: hasilnya deterministik dari isi gambar dan
BUKAN pengenalan makanan sungguhan. Untuk memasang model asli:
  1. Taruh file model di models/ (mis. food_model.h5) dan sesuaikan class_labels.json.
  2. Implementasikan `load_real_model()` di bawah: muat model, ubah gambar menjadi
     tensor sesuai input model, dan kembalikan objek dengan method
     `predict(data: bytes) -> List[float]` (probabilitas per kelas, urut sesuai label).
  3. Set atribut `is_stub = False` pada objek tersebut.
"""
import hashlib
import json
from functools import lru_cache
from typing import List, Optional

from app.config import LABELS_PATH


def load_labels() -> List[str]:
    with open(LABELS_PATH, encoding="utf-8") as f:
        return json.load(f)["classes"]


class StubModel:
    is_stub = True

    def __init__(self, labels: List[str]):
        self.labels = labels

    def predict(self, data: bytes) -> List[float]:
        """Mengembalikan skor probabilitas untuk tiap kelas."""
        digest = hashlib.sha256(data).digest()
        raw = [digest[i % len(digest)] + 1 for i in range(len(self.labels))]
        # Beri bobot besar pada satu kelas agar ada pemenang yang jelas.
        winner = digest[0] % len(self.labels)
        raw[winner] += 400
        total = float(sum(raw))
        return [r / total for r in raw]


def load_real_model() -> Optional[object]:
    """Titik pemasangan model asli. Kembalikan None bila belum tersedia."""
    return None


@lru_cache(maxsize=1)
def get_model():
    return load_real_model() or StubModel(load_labels())
