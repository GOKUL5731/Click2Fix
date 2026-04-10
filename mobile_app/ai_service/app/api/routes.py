from fastapi import APIRouter

from app.schemas.face import FaceVerifyRequest, FaceVerifyResponse
from app.schemas.fraud import FraudScoreRequest, FraudScoreResponse
from app.schemas.issue import (
    DetectIssueRequest,
    DetectIssueResponse,
    PredictPriceRequest,
    PredictPriceResponse,
)
from app.schemas.media import (
    ImageAnalysisRequest,
    ImageAnalysisFileRequest,
    ImageAnalysisResponse,
    VoiceTranscriptionRequest,
    VoiceTranscriptionResponse,
)
from app.services.face_verification import verify_face
from app.services.fraud_detection import score_fraud
from app.services.image_analysis import analyze_image_from_url, analyze_image_from_base64
from app.services.price_prediction import predict_price
from app.services.repair_detection import detect_issue
from app.services.speech_to_text import transcribe_audio

router = APIRouter()


@router.post("/detect-issue", response_model=DetectIssueResponse)
def detect_issue_endpoint(payload: DetectIssueRequest) -> DetectIssueResponse:
    return detect_issue(payload)


@router.post("/predict-price", response_model=PredictPriceResponse)
def predict_price_endpoint(payload: PredictPriceRequest) -> PredictPriceResponse:
    minimum, maximum = predict_price(payload.category, payload.urgency)
    return PredictPriceResponse(
        category=payload.category,
        minPrice=minimum,
        maxPrice=maximum,
        modelVersion="heuristic-price-v1",
    )


@router.post("/fraud-score", response_model=FraudScoreResponse)
def fraud_score_endpoint(payload: FraudScoreRequest) -> FraudScoreResponse:
    return score_fraud(payload)


@router.post("/verify-face", response_model=FaceVerifyResponse)
def verify_face_endpoint(payload: FaceVerifyRequest) -> FaceVerifyResponse:
    return verify_face(payload)


@router.post("/analyze-image", response_model=ImageAnalysisResponse)
def analyze_image_endpoint(payload: ImageAnalysisRequest) -> ImageAnalysisResponse:
    result = analyze_image_from_url(payload.imageUrl)
    return ImageAnalysisResponse(**result)


@router.post("/analyze-image-file", response_model=ImageAnalysisResponse)
def analyze_image_file_endpoint(payload: ImageAnalysisFileRequest) -> ImageAnalysisResponse:
    result = analyze_image_from_base64(payload.file_base64, payload.mimetype)
    return ImageAnalysisResponse(**result)


@router.post("/transcribe-voice", response_model=VoiceTranscriptionResponse)
def transcribe_voice_endpoint(payload: VoiceTranscriptionRequest) -> VoiceTranscriptionResponse:
    result = transcribe_audio(payload.file_base64, payload.mimetype, payload.filename)
    return VoiceTranscriptionResponse(**result)
