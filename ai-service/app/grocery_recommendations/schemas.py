from typing import List, Optional

from pydantic import BaseModel, Field


class GroceryRequest(BaseModel):
    budget_idr: int = Field(..., ge=10000, description="Anggaran total (Rp)")
    days: int = Field(7, ge=1, le=30)
    target_calories: int = Field(..., ge=800, le=6000, description="Kalori per hari")
    target_protein_g: int = Field(..., ge=20, le=400, description="Protein per hari")
    exclude: List[str] = Field(default_factory=list, description="id bahan yang dihindari")


class GroceryLine(BaseModel):
    item_id: str
    name: str
    category: str
    grams: int
    cost_idr: int
    calories: float
    protein_g: float


class GroceryResponse(BaseModel):
    items: List[GroceryLine]
    total_cost_idr: int
    budget_idr: int
    within_budget: bool
    total_calories: float
    total_protein_g: float
    daily_calories: float
    daily_protein_g: float
    meets_protein_target: bool
    meets_calorie_target: bool
    notes: List[str]


class SubstitutionRequest(BaseModel):
    item_id: str
    exclude: List[str] = Field(default_factory=list)


class Substitute(BaseModel):
    item_id: str
    name: str
    price_per_kg_idr: int
    protein_g_per_100g: float
    note: str


class SubstitutionResponse(BaseModel):
    original: Optional[str]
    substitutes: List[Substitute]
