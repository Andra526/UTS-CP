import json
from functools import lru_cache

from app.config import DATA_DIR
from app.food_detection.predictor import predict_top_k
from app.food_detection.preprocessing import validate_image
from app.food_detection.schemas import (
    FoodDetectionResponse,
    Nutrition,
    Prediction,
)


@lru_cache(maxsize=1)
def load_dictionary() -> dict:
    with open(DATA_DIR / "nutrition_food_dictionary.json", encoding="utf-8") as f:
        return json.load(f)["foods"]


def detect_food(data: bytes) -> FoodDetectionResponse:
    validate_image(data)
    foods = load_dictionary()
    ranked, is_stub = predict_top_k(data, k=3)

    preds = [
        Prediction(
            label=label,
            name=foods[label]["name"],
            confidence=round(score, 4),
        )
        for label, score in ranked
    ]
    info = foods[preds[0].label]
    return FoodDetectionResponse(
        top=preds[0],
        alternatives=preds[1:],
        nutrition=Nutrition(
            serving=info["serving"],
            calories=info["calories"],
            protein_g=info["protein_g"],
            carbs_g=info["carbs_g"],
            fat_g=info["fat_g"],
        ),
        is_stub=is_stub,
        note=(
            "Hasil contoh (stub): belum memakai model AI sungguhan."
            if is_stub
            else "Hasil dari model AI."
        ),
    )
