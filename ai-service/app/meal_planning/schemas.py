from typing import List

from pydantic import BaseModel, Field


class MealPlanRequest(BaseModel):
    target_calories: int = Field(..., ge=1000, le=6000)
    target_protein_g: int = Field(..., ge=30, le=400)


class MealItem(BaseModel):
    food: str
    name: str
    serving: str
    quantity: float
    calories: float
    protein_g: float


class Meal(BaseModel):
    category: str
    time: str
    items: List[MealItem]
    calories: float
    protein_g: float


class MealPlanResponse(BaseModel):
    meals: List[Meal]
    total_calories: float
    total_protein_g: float
    target_calories: int
    target_protein_g: int
    is_stub: bool
    note: str
