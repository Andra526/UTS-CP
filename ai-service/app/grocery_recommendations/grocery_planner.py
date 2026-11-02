"""Menyusun daftar belanja yang memenuhi target protein & kalori sesuai anggaran.

Pendekatan sederhana (greedy), cukup untuk demo:
  1. Penuhi protein harian dengan bahan protein paling efisien (protein per rupiah).
  2. Penuhi sisa kalori dengan karbo yang paling murah per kalori.
  3. Tambah sayur & buah dalam porsi tetap bila anggaran masih cukup.
"""
from typing import Dict, List

from app.grocery_recommendations.budget_calculator import cost_for, totals
from app.grocery_recommendations.recommendation_engine import (
    calories_per_rupiah,
    candidates,
    load_items,
    load_prices,
    protein_per_rupiah,
)
from app.grocery_recommendations.schemas import GroceryLine, GroceryRequest, GroceryResponse

# Satu jenis protein dibatasi agar menu tidak monoton
MAX_SHARE_PER_PROTEIN = 0.5


def _line(item_id: str, grams: float) -> Dict:
    item = load_items()[item_id]
    grams = max(0, int(round(grams / 10.0) * 10))
    return {
        "item_id": item_id,
        "name": item["name"],
        "category": item["category"],
        "grams": grams,
        "cost_idr": cost_for(grams, load_prices()[item_id]),
        "calories": round(item["calories"] * grams / 100.0, 1),
        "protein_g": round(item["protein_g"] * grams / 100.0, 1),
    }


def plan(req: GroceryRequest) -> GroceryResponse:
    items = load_items()
    lines: List[Dict] = []
    notes: List[str] = []

    total_protein_need = req.target_protein_g * req.days
    total_cal_need = req.target_calories * req.days

    # 1) Protein
    proteins = sorted(
        candidates("protein", req.exclude), key=protein_per_rupiah, reverse=True
    )[:3]
    if not proteins:
        notes.append("Tidak ada bahan protein tersedia (semua dikecualikan).")
    else:
        # Bagi kebutuhan protein ke 2-3 bahan teratas agar bervariasi
        share = 1.0 / len(proteins)
        if len(proteins) == 1:
            share = 1.0
        for pid in proteins:
            need_protein = total_protein_need * min(share, 1.0)
            grams = need_protein / items[pid]["protein_g"] * 100.0
            lines.append(_line(pid, grams))

    # 2) Karbo untuk sisa kalori
    cal_so_far = sum(l["calories"] for l in lines)
    remaining_cal = max(0.0, total_cal_need - cal_so_far)
    # sisihkan ~10% kalori untuk sayur/buah
    carb_cal = remaining_cal * 0.9
    carbs = sorted(candidates("karbo", req.exclude), key=calories_per_rupiah, reverse=True)
    if carbs and carb_cal > 0:
        cid = carbs[0]
        lines.append(_line(cid, carb_cal / items[cid]["calories"] * 100.0))
    elif not carbs:
        notes.append("Tidak ada bahan karbohidrat tersedia.")

    # 3) Sayur & buah (porsi tetap: 150 g sayur + 100 g buah per hari)
    for cat, grams_per_day in (("sayur", 150), ("buah", 100)):
        pool = sorted(candidates(cat, req.exclude), key=lambda i: load_prices()[i])
        if pool:
            lines.append(_line(pool[0], grams_per_day * req.days))

    # Skala turun jika melebihi anggaran
    t = totals(lines)
    if t["cost"] > req.budget_idr and t["cost"] > 0:
        factor = req.budget_idr / t["cost"]
        lines = [_line(l["item_id"], l["grams"] * factor) for l in lines]
        notes.append(
            "Anggaran tidak cukup untuk target penuh; porsi dikurangi proporsional. "
            "Naikkan anggaran atau turunkan target."
        )
        t = totals(lines)

    daily_cal = t["calories"] / req.days
    daily_pro = t["protein"] / req.days
    meets_pro = daily_pro >= req.target_protein_g * 0.95
    meets_cal = daily_cal >= req.target_calories * 0.9
    if not meets_pro:
        notes.append("Target protein belum tercapai.")
    if not meets_cal:
        notes.append("Target kalori belum tercapai.")
    notes.append("Harga memakai data contoh; sesuaikan dengan harga pasar sebenarnya.")

    return GroceryResponse(
        items=[GroceryLine(**l) for l in lines if l["grams"] > 0],
        total_cost_idr=int(t["cost"]),
        budget_idr=req.budget_idr,
        within_budget=t["cost"] <= req.budget_idr,
        total_calories=t["calories"],
        total_protein_g=t["protein"],
        daily_calories=round(daily_cal, 1),
        daily_protein_g=round(daily_pro, 1),
        meets_protein_target=meets_pro,
        meets_calorie_target=meets_cal,
        notes=notes,
    )
