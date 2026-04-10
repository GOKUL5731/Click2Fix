# Click2Fix

Click2Fix is an AI-powered home repair and service marketplace.

Tagline: "Click the problem. Fix it instantly."

This repository contains a production-minded hackathon scaffold for:

- Flutter user app for Android, iOS, and Windows
- Flutter worker app
- Flutter web admin panel
- Node.js, Express, TypeScript backend
- Python FastAPI AI service
- PostgreSQL schema and database design
- Docker-based local deployment starter
- Product architecture, wireframes, flows, and roadmap docs

## Product Flow

1. User logs in with mobile OTP and optional face verification.
2. User uploads an issue by photo, video, voice, or text.
3. AI detects category, urgency, and estimated price.
4. Backend searches verified nearby workers by skill, location, rating, trust score, and availability.
5. Workers receive the request in real time and submit quote plus arrival time.
6. User compares quotes and confirms a booking.
7. Live tracking, chat, payment, review, and invoice complete the job.
8. Admin panel monitors workers, bookings, fraud, revenue, and emergencies.

## Repository Layout

```text
click2fix/
|-- mobile_app/
|-- worker_app/
|-- admin_panel/
|-- backend/
|-- ai_service/
|-- database/
|-- docs/
|-- deployment/
```

## MVP Targets

- Login and OTP verification
- Upload household issue
- AI category and urgency detection
- Nearby worker list
- Quotation comparison
- Booking creation
- Socket.IO tracking and booking status events
- Emergency request path
- Admin worker approval queue

## Local Development

Backend:

```bash
cd backend
npm install
cp .env.example .env
npm run dev
```

AI service:

```bash
cd ai_service
python -m venv .venv
.venv/Scripts/activate
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8001
```

Database:

```bash
psql -d click2fix -f database/schema.sql
```

Docker compose:

```bash
cd deployment
docker compose up --build
```

Flutter apps are intentionally lightweight scaffolds. Create full Flutter platforms with `flutter create .` inside each app folder before running on device, then keep the existing `lib/` files.

