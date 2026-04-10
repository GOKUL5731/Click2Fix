from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.routes import router

app = FastAPI(
    title="Click2Fix AI Service",
    version="0.2.0",
    description="AI triage, image analysis, voice transcription, pricing, face verification, and fraud scoring for Click2Fix.",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok", "service": "click2fix-ai-service"}


app.include_router(router, prefix="/ai", tags=["ai"])
