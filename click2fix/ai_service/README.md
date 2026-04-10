# Click2Fix AI Service

FastAPI service for:

- Repair type detection
- Urgency detection
- Price prediction
- Fraud detection
- Face verification

Run:

```bash
python -m venv .venv
.venv/Scripts/activate
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8001
```

MVP behavior is deterministic and rules-based so the end-to-end product can be demoed without trained model files. Production models should be loaded behind the existing service functions.

