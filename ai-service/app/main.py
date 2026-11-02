from fastapi import FastAPI

from app.food_detection.router import router as food_router
from app.grocery_recommendations.router import router as grocery_router
from app.meal_planning.router import router as meal_router
from app.nutrition_chatbot.router import router as chatbot_router

app = FastAPI(
    title="GymFit AI Service",
    version="1.0.0",
    description="Layanan AI GymFit. Versi awal memakai hasil contoh (stub) "
    "agar integrasi dengan backend bisa diuji sebelum model asli dipasang.",
)

app.include_router(food_router)
app.include_router(grocery_router)
app.include_router(meal_router)
app.include_router(chatbot_router)


@app.get("/health", tags=["health"])
def health():
    return {"status": "ok", "service": "gymfit-ai"}
