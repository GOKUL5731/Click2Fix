from fastapi import FastAPI

from app.api.routes import router

app = FastAPI(
    title="Click2Fix AI Service",
    version="0.1.0",
    description="AI triage, pricing, face verification, and fraud scoring for Click2Fix.",
)


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok", "service": "click2fix-ai-service"}


app.include_router(router, prefix="/ai", tags=["ai"])

