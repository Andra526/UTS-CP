from fastapi import APIRouter, File, UploadFile

from app.food_detection.schemas import FoodDetectionResponse
from app.food_detection.service import detect_food, load_dictionary

router = APIRouter(prefix="/food", tags=["food-detection"])


@router.post("/detect", response_model=FoodDetectionResponse)
async def detect(image: UploadFile = File(...)):
    """Unggah foto makanan -> tebakan makanan + estimasi gizi per porsi."""
    data = await image.read()
    return detect_food(data)


@router.get("/dictionary")
def dictionary():
    """Kamus gizi makanan (untuk fitur nutrition_dictionary)."""
    return {"foods": load_dictionary()}
