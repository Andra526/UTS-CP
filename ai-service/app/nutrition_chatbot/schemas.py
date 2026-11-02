from typing import Optional

from pydantic import BaseModel, Field


class ChatRequest(BaseModel):
    message: str = Field(..., min_length=1, max_length=1000)
    goal: Optional[str] = Field(None, description="mis. bulking / cutting / maintenance")


class ChatResponse(BaseModel):
    reply: str
    topic: str
    is_stub: bool
    disclaimer: str
