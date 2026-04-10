from app.schemas.issue import Urgency

BASE_PRICES: dict[str, tuple[int, int]] = {
    "plumbing": (300, 800),
    "electrical": (350, 1000),
    "carpentry": (400, 1200),
    "cleaning": (500, 1500),
    "painting": (800, 5000),
    "appliance_repair": (500, 2500),
    "gas_leakage": (500, 1500),
}

URGENCY_MULTIPLIER: dict[Urgency, float] = {
    "low": 1.0,
    "medium": 1.1,
    "high": 1.35,
    "critical": 1.75,
}


def predict_price(category: str, urgency: Urgency) -> tuple[int, int]:
    minimum, maximum = BASE_PRICES.get(category, (300, 1000))
    multiplier = URGENCY_MULTIPLIER[urgency]
    return round(minimum * multiplier), round(maximum * multiplier)

