"""Validasi dan penyiapan gambar sebelum masuk ke model."""
from fastapi import HTTPException

from app.config import MAX_IMAGE_BYTES

_MAGIC = {
    b"\xff\xd8\xff": "image/jpeg",
    b"\x89PNG\r\n\x1a\n": "image/png",
    b"RIFF": "image/webp",
}


def detect_image_type(data: bytes) -> str | None:
    for magic, mime in _MAGIC.items():
        if data.startswith(magic):
            return mime
    return None


def validate_image(data: bytes) -> bytes:
    if not data:
        raise HTTPException(status_code=400, detail="File gambar kosong")
    if len(data) > MAX_IMAGE_BYTES:
        raise HTTPException(status_code=413, detail="Ukuran gambar terlalu besar")
    if detect_image_type(data) is None:
        raise HTTPException(
            status_code=415, detail="Format harus JPEG, PNG, atau WebP"
        )
    return data
