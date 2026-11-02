"""Saran bahan pengganti dalam kategori yang sama."""
from typing import List

from app.grocery_recommendations.recommendation_engine import (
    candidates,
    load_items,
    load_prices,
)
from app.grocery_recommendations.schemas import Substitute


def find_substitutes(item_id: str, exclude: List[str], limit: int = 3) -> List[Substitute]:
    items = load_items()
    if item_id not in items:
        return []
    original = items[item_id]
    pool = [c for c in candidates(original["category"], exclude) if c != item_id]
    prices = load_prices()

    result: List[Substitute] = []
    for cid in pool:
        it = items[cid]
        cheaper = prices[cid] < prices[item_id]
        protein_diff = it["protein_g"] - original["protein_g"]
        if cheaper and protein_diff >= -3:
            note = "Lebih murah dengan protein serupa"
        elif protein_diff > 3:
            note = "Protein lebih tinggi"
        elif cheaper:
            note = "Lebih murah, protein lebih rendah"
        else:
            note = "Alternatif sekategori"
        result.append(
            Substitute(
                item_id=cid,
                name=it["name"],
                price_per_kg_idr=prices[cid],
                protein_g_per_100g=it["protein_g"],
                note=note,
            )
        )
    # Urutkan: yang lebih murah dulu
    result.sort(key=lambda s: s.price_per_kg_idr)
    return result[:limit]
