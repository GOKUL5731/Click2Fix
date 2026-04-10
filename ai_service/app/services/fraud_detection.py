from app.schemas.fraud import FraudScoreRequest, FraudScoreResponse


def score_fraud(payload: FraudScoreRequest) -> FraudScoreResponse:
    risk = 0.0
    rules: list[str] = []

    if payload.duplicateFaceCount and payload.duplicateFaceCount > 0:
        risk += min(40, payload.duplicateFaceCount * 20)
        rules.append("Duplicate face signal")

    if payload.price and payload.category:
        suspicious_price = payload.price > 10000 or payload.price < 100
        if suspicious_price:
            risk += 25
            rules.append("Unusual price")

    if payload.recentCancellationRate and payload.recentCancellationRate > 0.5:
        risk += 25
        rules.append("High recent cancellation rate")

    if payload.ratingCount == 0 and payload.entityType == "worker":
        risk += 5
        rules.append("New worker profile")

    risk = min(100, risk)
    status = "high_risk" if risk >= 70 else "review" if risk >= 35 else "clear"

    return FraudScoreResponse(
        riskScore=risk,
        status=status,
        triggeredRules=rules,
        modelVersion="rules-mvp-v1",
    )

