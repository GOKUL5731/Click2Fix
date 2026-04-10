from pydantic import BaseModel, Field


class FraudScoreRequest(BaseModel):
    entityType: str
    entityId: str
    price: float | None = None
    category: str | None = None
    ratingCount: int | None = 0
    duplicateFaceCount: int | None = 0
    recentCancellationRate: float | None = Field(default=0, ge=0, le=1)


class FraudScoreResponse(BaseModel):
    riskScore: float = Field(ge=0, le=100)
    status: str
    triggeredRules: list[str]
    modelVersion: str

