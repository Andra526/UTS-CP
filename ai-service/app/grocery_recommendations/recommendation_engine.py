"""Memuat data bahan & harga, serta menghitung efisiensi (protein per rupiah)."""
import json
from functools import lru_cache
from typing import Dict, List

from app.config import DATA_DIR


@lru_cache(maxsize=1)
def load_items() -> Dict[str, dict]:
    with open(DATA_DIR / "grocery_items.json", encoding="utf-8") as f:
        return {i["id"]: i for i in json.load(f)["items"]}


@lru_cache(maxsize=1)
def load_prices() -> Dict[str, int]:
    with open(DATA_DIR / "sample_prices.json", encoding="utf-8") as f:
        return json.load(f)["prices"]


def protein_per_rupiah(item_id: str) -> float:
    """Gram protein yang didapat per Rp 1.000."""
    item = load_items()[item_id]
    price_per_100g = load_prices()[item_id] / 10.0
    return item["protein_g"] / price_per_100g * 1000.0


def calories_per_rupiah(item_id: str) -> float:
    item = load_items()[item_id]
    price_per_100g = load_prices()[item_id] / 10.0
    return item["calories"] / price_per_100g * 1000.0


def candidates(category: str, exclude: List[str]) -> List[str]:
    return [
        i
        for i, it in load_items().items()
        if it["category"] == category and i not in exclude
    ]
