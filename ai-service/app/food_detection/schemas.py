from typing import List

from pydantic import BaseModel


class Nutrition(BaseModel):
    serving: str
    calories: float
    protein_g: float
    carbs_g: float
    fat_g: float


class Prediction(BaseModel):
    label: str
    name: str
    confidence: float


class FoodDetectionResponse(BaseModel):
    top: Prediction
    alternatives: List[Prediction]
    nutrition: Nutrition
    is_stub: bool
    note: str
