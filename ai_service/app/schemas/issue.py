from typing import Literal

from pydantic import BaseModel, Field, HttpUrl

Urgency = Literal["low", "medium", "high", "critical"]


class DetectIssueRequest(BaseModel):
    description: str | None = Field(default=None, max_length=2000)
    imageUrl: HttpUrl | None = None
    videoUrl: HttpUrl | None = None
    latitude: float | None = None
    longitude: float | None = None


class DetectIssueResponse(BaseModel):
    category: str
    confidence: float = Field(ge=0, le=1)
    urgency: Urgency
    estimatedPriceMin: int
    estimatedPriceMax: int
    explanation: list[str]
    modelVersion: str


class PredictPriceRequest(BaseModel):
    category: str
    city: str | None = None
    urgency: Urgency = "medium"
    workerHistoryCount: int | None = Field(default=0, ge=0)


class PredictPriceResponse(BaseModel):
    category: str
    minPrice: int
    maxPrice: int
    currency: str = "INR"
    modelVersion: str

