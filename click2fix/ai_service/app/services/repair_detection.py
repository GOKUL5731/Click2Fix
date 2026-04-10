from app.schemas.issue import DetectIssueRequest, DetectIssueResponse
from app.services.price_prediction import predict_price
from app.services.urgency_detection import detect_urgency


KEYWORDS: list[tuple[str, tuple[str, ...], float]] = [
    ("gas_leakage", ("gas", "cylinder", "smell"), 0.9),
    ("plumbing", ("pipe", "tap", "leak", "water", "drain"), 0.86),
    ("electrical", ("fan", "switch", "wire", "spark", "light", "short circuit"), 0.83),
    ("carpentry", ("door", "wood", "hinge", "lock", "cabinet"), 0.78),
    ("cleaning", ("clean", "dust", "deep clean", "bathroom"), 0.76),
    ("painting", ("paint", "wall", "crack", "patch"), 0.74),
    ("appliance_repair", ("fridge", "washing", "ac", "mixer", "oven"), 0.8),
]


def detect_issue(payload: DetectIssueRequest) -> DetectIssueResponse:
    text = (payload.description or "").lower()

    for category, keywords, confidence in KEYWORDS:
        matched = [keyword for keyword in keywords if keyword in text]
        if matched:
            urgency, urgency_rules = detect_urgency(category, text)
            minimum, maximum = predict_price(category, urgency)
            return DetectIssueResponse(
                category=category,
                confidence=confidence,
                urgency=urgency,
                estimatedPriceMin=minimum,
                estimatedPriceMax=maximum,
                explanation=[f"Matched keywords: {', '.join(matched)}", *urgency_rules],
                modelVersion="heuristic-mvp-v1",
            )

    fallback_category = "cleaning" if not payload.imageUrl and not payload.videoUrl else "plumbing"
    urgency, urgency_rules = detect_urgency(fallback_category, text)
    minimum, maximum = predict_price(fallback_category, urgency)
    return DetectIssueResponse(
        category=fallback_category,
        confidence=0.52,
        urgency=urgency,
        estimatedPriceMin=minimum,
        estimatedPriceMax=maximum,
        explanation=["No strong keyword match; used MVP fallback", *urgency_rules],
        modelVersion="heuristic-mvp-v1",
    )

