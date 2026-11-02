from fastapi import APIRouter, HTTPException

from app.grocery_recommendations.grocery_planner import plan
from app.grocery_recommendations.recommendation_engine import load_items
from app.grocery_recommendations.schemas import (
    GroceryRequest,
    GroceryResponse,
    SubstitutionRequest,
    SubstitutionResponse,
)
from app.grocery_recommendations.substitution_engine import find_substitutes

router = APIRouter(prefix="/grocery", tags=["grocery-recommendations"])


@router.post("/recommendations", response_model=GroceryResponse)
def recommend(req: GroceryRequest):
    return plan(req)


@router.post("/substitutions", response_model=SubstitutionResponse)
def substitutions(req: SubstitutionRequest):
    items = load_items()
    if req.item_id not in items:
        raise HTTPException(status_code=404, detail="Bahan tidak ditemukan")
    return SubstitutionResponse(
        original=items[req.item_id]["name"],
        substitutes=find_substitutes(req.item_id, req.exclude),
    )
