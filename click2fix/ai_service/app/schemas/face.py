from pydantic import BaseModel, HttpUrl


class FaceVerifyRequest(BaseModel):
    selfieUrl: HttpUrl
    documentFaceUrl: HttpUrl


class FaceVerifyResponse(BaseModel):
    matched: bool
    confidence: float
    needsManualReview: bool
    modelVersion: str

