from fastapi import APIRouter

from app.nutrition_chatbot.schemas import ChatRequest, ChatResponse
from app.nutrition_chatbot.service import answer

router = APIRouter(prefix="/chatbot", tags=["nutrition-chatbot"])


@router.post("/message", response_model=ChatResponse)
def message(req: ChatRequest):
    return answer(req)
