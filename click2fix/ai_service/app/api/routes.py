from fastapi import APIRouter

from app.schemas.face import FaceVerifyRequest, FaceVerifyResponse
from app.schemas.fraud import FraudScoreRequest, FraudScoreResponse
from app.schemas.issue import (
    DetectIssueRequest,
    DetectIssueResponse,
    PredictPriceRequest,
    PredictPriceResponse,
)
from app.services.face_verification import verify_face
from app.services.fraud_detection import score_fraud
from app.services.price_prediction import predict_price
from app.services.repair_detection import detect_issue

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

