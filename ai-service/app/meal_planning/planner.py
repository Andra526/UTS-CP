"""Penyusun meal plan harian berbasis aturan (bukan model ML)."""
from app.food_detection.service import load_dictionary
from app.meal_planning.schemas import Meal, MealItem, MealPlanRequest, MealPlanResponse

# (kategori, jam, porsi kalori, makanan utama protein, makanan pendamping)
TEMPLATE = [
    ("Sarapan", "07:30", 0.25, "telur_rebus", ["oatmeal", "pisang"]),
    ("Makan Siang", "12:30", 0.30, "ayam_dada_rebus", ["nasi_merah", "brokoli_kukus"]),
    ("Snack Sore", "16:30", 0.15, "greek_yogurt", ["pisang"]),
    ("Makan Malam", "20:00", 0.30, "daging_sapi", ["kentang_panggang", "brokoli_kukus"]),
]


def _item(food_id: str, qty: float) -> MealItem:
    f = load_dictionary()[food_id]
    return MealItem(
        food=food_id,
        name=f["name"],
        serving=f["serving"],
        quantity=round(qty, 1),
        calories=round(f["calories"] * qty, 1),
        protein_g=round(f["protein_g"] * qty, 1),
    )


def _round_q(q: float) -> float:
    """Pembulatan ke kelipatan 0,25 porsi, minimal 0,5 dan maksimal 4."""
    return min(4.0, max(0.5, round(q * 4) / 4))


def _build(req: MealPlanRequest, scale: float):
    foods = load_dictionary()
    meals = []
    for category, time, share, main, sides in TEMPLATE:
        meal_cal = req.target_calories * share
        meal_pro = req.target_protein_g * share

        # Porsi utama: penuhi protein meal
        main_qty = _round_q(meal_pro * 0.7 / foods[main]["protein_g"] * scale)
        items = [_item(main, main_qty)]
        used = sum(i.calories for i in items)

        # Pendamping: isi sisa kalori secara merata
        remaining = max(0.0, meal_cal - used)
        for s in sides:
            qty = _round_q(remaining / len(sides) / foods[s]["calories"] * scale)
            items.append(_item(s, qty))

        meals.append(
            Meal(
                category=category,
                time=time,
                items=items,
                calories=round(sum(i.calories for i in items), 1),
                protein_g=round(sum(i.protein_g for i in items), 1),
            )
        )
    return meals


def generate(req: MealPlanRequest) -> MealPlanResponse:
    # Susun, lalu koreksi skala porsi beberapa kali agar mendekati target kalori.
    scale = 1.0
    meals = _build(req, scale)
    for _ in range(4):
        total = sum(m.calories for m in meals)
        if total <= 0 or abs(total - req.target_calories) / req.target_calories < 0.05:
            break
        scale *= req.target_calories / total
        meals = _build(req, scale)

    return MealPlanResponse(
        meals=meals,
        total_calories=round(sum(m.calories for m in meals), 1),
        total_protein_g=round(sum(m.protein_g for m in meals), 1),
        target_calories=req.target_calories,
        target_protein_g=req.target_protein_g,
        is_stub=True,
        note="Menu disusun dari template aturan sederhana, bukan model AI. "
        "Konsultasikan dengan PT/ahli gizi.",
    )
