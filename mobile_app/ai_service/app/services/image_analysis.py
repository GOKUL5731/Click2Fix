import os
import base64
import io
from typing import Optional

from PIL import Image

# Category mapping for image-detected problems
CATEGORY_MAP = {
    "pipe": "plumbing",
    "faucet": "plumbing",
    "leak": "plumbing",
    "water": "plumbing",
    "drain": "plumbing",
    "toilet": "plumbing",
    "wire": "electrical",
    "socket": "electrical",
    "switch": "electrical",
    "spark": "electrical",
    "fan": "electrical",
    "light": "electrical",
    "circuit": "electrical",
    "door": "carpentry",
    "wood": "carpentry",
    "hinge": "carpentry",
    "lock": "carpentry",
    "cabinet": "carpentry",
    "paint": "painting",
    "wall": "painting",
    "crack": "painting",
    "peel": "painting",
    "gas": "gas_leakage",
    "stove": "gas_leakage",
    "cylinder": "gas_leakage",
    "fridge": "appliance_repair",
    "washing": "appliance_repair",
    "ac": "appliance_repair",
    "oven": "appliance_repair",
    "clean": "cleaning",
    "dust": "cleaning",
    "mold": "cleaning",
}

OPENAI_API_KEY = os.getenv("OPENAI_API_KEY", "")


def analyze_image_from_url(image_url: str) -> dict:
    """Analyze an image from a URL and return problem description."""
    if not OPENAI_API_KEY:
        return _fallback_analysis(image_url)

    try:
        import openai

        client = openai.OpenAI(api_key=OPENAI_API_KEY)
        response = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {
                    "role": "system",
                    "content": (
                        "You are an AI assistant for a home repair service. "
                        "Analyze the image and describe the problem you see. "
                        "Identify the type of repair needed (plumbing, electrical, carpentry, painting, cleaning, appliance repair, gas leakage). "
                        "Be specific about what's broken or damaged. "
                        "Respond in JSON format: {\"description\": \"...\", \"category\": \"...\", \"confidence\": 0.0-1.0, \"details\": [\"...\"]}"
                    ),
                },
                {
                    "role": "user",
                    "content": [
                        {"type": "text", "text": "What problem do you see in this image? Describe it for a repair service."},
                        {"type": "image_url", "image_url": {"url": image_url}},
                    ],
                },
            ],
            max_tokens=500,
        )

        import json

        text = response.choices[0].message.content or ""
        # Try to parse JSON from response
        try:
            # Strip markdown code blocks if present
            clean = text.strip()
            if clean.startswith("```"):
                clean = clean.split("\n", 1)[1]
                clean = clean.rsplit("```", 1)[0]
            result = json.loads(clean)
            return {
                "description": result.get("description", "Problem detected in image"),
                "category": result.get("category", "cleaning"),
                "confidence": float(result.get("confidence", 0.75)),
                "details": result.get("details", ["Analyzed by AI vision"]),
            }
        except json.JSONDecodeError:
            return {
                "description": text[:500],
                "category": _guess_category(text),
                "confidence": 0.65,
                "details": ["AI vision analysis completed"],
            }

    except Exception as e:
        print(f"[AI-IMAGE] OpenAI analysis failed: {e}")
        return _fallback_analysis(image_url)


def analyze_image_from_base64(file_base64: str, mimetype: str = "image/jpeg") -> dict:
    """Analyze an image from base64 data."""
    if not OPENAI_API_KEY:
        return _fallback_analysis("")

    try:
        data_url = f"data:{mimetype};base64,{file_base64}"
        return analyze_image_from_url(data_url)
    except Exception as e:
        print(f"[AI-IMAGE] Base64 analysis failed: {e}")
        return _fallback_analysis("")


def _guess_category(text: str) -> str:
    """Guess category from text description."""
    lower = text.lower()
    for keyword, category in CATEGORY_MAP.items():
        if keyword in lower:
            return category
    return "cleaning"


def _fallback_analysis(image_url: str) -> dict:
    """Fallback when OpenAI is not available."""
    return {
        "description": "Image uploaded successfully. Please describe the problem manually or our team will review it.",
        "category": "unknown",
        "confidence": 0.0,
        "details": ["AI image analysis not available - manual review required"],
    }
