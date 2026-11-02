from fastapi import APIRouter

from app.meal_planning.planner import generate
from app.meal_planning.schemas import MealPlanRequest, MealPlanResponse

router = APIRouter(prefix="/meal-plans", tags=["meal-planning"])


@router.post("/generate", response_model=MealPlanResponse)
def generate_plan(req: MealPlanRequest):
    return generate(req)
