from app.schemas.issue import Urgency


def detect_urgency(category: str, text: str) -> tuple[Urgency, list[str]]:
    normalized = text.lower()
    rules: list[str] = []

    if "gas" in normalized or category == "gas_leakage":
        rules.append("Gas leakage is always critical")
        return "critical", rules

    if "short circuit" in normalized or "spark" in normalized:
        rules.append("Electrical short circuit keyword found")
        return "high", rules

    if "leak" in normalized or "burst" in normalized or "flood" in normalized:
        rules.append("Water leakage keyword found")
        return "high", rules

    if "fan" in normalized or "switch" in normalized:
        rules.append("Electrical appliance repair usually starts at medium urgency")
        return "medium", rules

    if "paint" in normalized or category == "painting":
        rules.append("Painting usually starts at low urgency")
        return "low", rules

    rules.append("Defaulted to medium urgency")
    return "medium", rules

