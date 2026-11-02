"""Perhitungan biaya & ringkasan gizi dari daftar belanja."""
from typing import Dict, List


def cost_for(grams: float, price_per_kg: float) -> int:
    return int(round(grams / 1000.0 * price_per_kg))


def totals(lines: List[Dict]) -> Dict[str, float]:
    return {
        "cost": sum(l["cost_idr"] for l in lines),
        "calories": round(sum(l["calories"] for l in lines), 1),
        "protein": round(sum(l["protein_g"] for l in lines), 1),
    }
