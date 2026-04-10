from app.schemas.face import FaceVerifyRequest, FaceVerifyResponse


def verify_face(_payload: FaceVerifyRequest) -> FaceVerifyResponse:
    # Production path: use DeepFace or FaceNet to compare selfie and document face.
    # MVP path: force manual review while preserving the API contract.
    return FaceVerifyResponse(
        matched=False,
        confidence=0.0,
        needsManualReview=True,
        modelVersion="manual-review-mvp-v1",
    )

