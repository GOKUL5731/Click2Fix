from pydantic import BaseModel, Field


class ImageAnalysisRequest(BaseModel):
    imageUrl: str = ""


class ImageAnalysisFileRequest(BaseModel):
    file_base64: str
    mimetype: str = "image/jpeg"
    filename: str = "image.jpg"


class ImageAnalysisResponse(BaseModel):
    description: str
    category: str
    confidence: float = Field(ge=0, le=1)
    details: list[str]


class VoiceTranscriptionRequest(BaseModel):
    file_base64: str
    mimetype: str = "audio/webm"
    filename: str = "audio.webm"


class VoiceTranscriptionResponse(BaseModel):
    text: str
    original_text: str | None = None
    language: str = "en"
    confidence: float = Field(ge=0, le=1, default=0)
