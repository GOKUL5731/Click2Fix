# Click2Fix Complete Project Architecture & Specification

## 1. Full Project Architecture
Click2Fix leverages a modern, distributed architecture for scalability, real-time communication, and AI features.

### Components:
*   **Unified Mobile App (Frontend)**: Built with Flutter. As explicitly requested, this single application will serve both **Users** and **Workers**. 
    *   *Role-based Routing*: Upon login, the app checks the user role (Customer vs. Worker). If a worker logs in, they are redirected to the Worker Dashboard. Customers go to the Home Dashboard.
    *   *Hardware Features*: Full integration with native Device Camera (for posting problems) and GPS (for auto-fetching problem location and worker live tracking).
*   **Admin Panel**: Flutter Web or React dashboard for managing the system.
*   **Backend System**: Node.js + Express + TypeScript serving REST APIs.
*   **Real-time Layer**: Socket.IO for chat, live tracking, and instant alerts.
*   **AI Service**: Python (FastAPI/Flask) microservice running models for Image classification (EfficientNet/MobileNetV3) and Price Prediction (XGBoost).
*   **Database Layer**: PostgreSQL for structured relationships and ACID transactions. Redis for caching OTPs, storing session states, and highly-updating data like live worker coordinates.

## 2. Ultra-Premium UI/UX Specifications (Frontend)

Click2Fix must wow users at first glance. Generic Material widgets are insufficient; the frontend must implement a highly polished, premium design system.

### Design Aesthetics & Tokens
*   **Color Palette**: Harmonious curations extending the brand. 
    *   *Primary Blue*: `#1976D2` (with soft glowing drop-shadows on interactive elements).
    *   *Emergency Red*: `#D32F2F` (pulsing micro-animations for high-urgency alerts).
    *   *Backgrounds*: Sleek `Light Mode` (`#F5F7FA`) and deep rich `Dark Mode` (`#0F172A`).
*   **Typography**: Modern Google Fonts (`Inter` or `Outfit`) for crisp readability over system defaults.
*   **Visual Elements**: 
    *   *Glassmorphism*: Frosted glass (`BackdropFilter`) for contextual overlays, like the AI loading sheet and bottom navigation.
    *   *Card-based UI*: Rounded corners (`BorderRadius.circular(24)`), very soft drop-shadows to add depth without clutter.
*   **Animations**: Built-in implicit animations (`Hero` transitions for images, `AnimatedContainer` for active states). Every button interaction should provide fluid tactile feedback.

### Architectural Wireframes (Shared unified app)

**1. Shared Screens (Auth & Setup)**
*   **Splash/Onboarding**: Vibrant gradient background, subtle fade-in logo, smooth carousel for the pitch.
*   **Role Selection**: Rich 3D-styled cards for "Customer" vs "Worker" selection.
*   **Profile Validation**: Immersive camera view for Face Verification with an automated oval face-guide.

**2. Customer Experience Contexts**
*   **Home Dashboard**: A clean, distraction-free view featuring a massive, visually striking central button ("Take Photo/Video"), pulsing with a subtle glowing loop. Emergency SOS button styled distinctly at the top right.
*   **Post Problem Screen**:
    1. Seamless, instantaneous Camera access within the primary view frame.
    2. GPS location silently stamped behind-the-scenes.
    3. An engaging, futuristic "AI Analyzing..." shimmer animation overlay.
*   **Worker Match**: Horizontal scrolling carousels for "Top Rated" workers. Expandable cards showing dynamic price/ETA sliders.

**3. Worker Experience Contexts**
*   **Worker Dashboard**: Real-world Map view with beautiful custom map markers for nearby requests. Floating summary cards sliding up from the bottom when tapped.
*   **Quote Submission**: A premium minimalist slider and clean text fields to quickly dispatch bids within seconds.

## 3. Database Schema (PostgreSQL)

```sql
CREATE TYPE user_role AS ENUM ('customer', 'worker', 'admin');
CREATE TYPE issue_status AS ENUM ('pending', 'assigned', 'in_progress', 'completed', 'cancelled');
CREATE TYPE issue_urgency AS ENUM ('low', 'medium', 'high', 'critical');

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    role user_role NOT NULL,
    name VARCHAR(255),
    phone VARCHAR(20) UNIQUE NOT NULL,
    email VARCHAR(255),
    profile_photo TEXT,
    face_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE workers_profile (
    user_id UUID PRIMARY KEY REFERENCES users(id),
    category VARCHAR(255),
    experience INT,
    aadhaar_number VARCHAR(12),
    aadhaar_verified BOOLEAN DEFAULT FALSE,
    trust_score INT DEFAULT 100,
    rating FLOAT DEFAULT 5.0,
    availability BOOLEAN DEFAULT FALSE,
    current_latitude DECIMAL(10, 8),
    current_longitude DECIMAL(11, 8),
    wallet_balance DECIMAL(10, 2) DEFAULT 0.00
);

CREATE TABLE issues (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    image_url TEXT,
    video_url TEXT,
    issue_type VARCHAR(100),
    urgency_level issue_urgency,
    description TEXT,
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    status issue_status DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE quotations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    issue_id UUID REFERENCES issues(id),
    worker_id UUID REFERENCES users(id),
    price DECIMAL(10, 2),
    estimated_time VARCHAR(100),
    message TEXT,
    status VARCHAR(50) DEFAULT 'pending'
);

CREATE TABLE bookings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    issue_id UUID REFERENCES issues(id),
    worker_id UUID REFERENCES users(id),
    user_id UUID REFERENCES users(id),
    booking_status VARCHAR(50),  -- e.g., 'confirmed', 'en_route', 'completed'
    payment_status VARCHAR(50),
    tracking_enabled BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

## 4. Backend APIs (TypeScript & Express Structure)
*   `POST /api/v1/auth/verify-otp` (Returns JWT with `{ id, role }`. The app uses the `role` to redirect the user to either the Customer Dashboard or Worker Dashboard.)
*   `POST /api/v1/issues/create` (Must include lat/lng obtained from GPS, and multiparty image data)
*   `GET /api/v1/worker/nearby` (Uses PostGIS/Redis GEO to find workers)
*   `POST /api/v1/worker/quote` (Worker sends a bid)

## 5. Real-time Socket.IO Flow
1. Worker connects: `socket.emit('worker:online', { lat, lng })`. Server adds to Redis.
2. User submits issue: Express API hits. Server queries Redis for nearest workers.
3. Server to Worker: `socket.to(worker_room).emit('issue:new', issueData)`.
4. Worker quotes: API hit + trigger tracking.
5. In-Transit: `setInterval` running on Worker app emitting `socket.emit('location:update', coord)`. Server forwards to User `socket.emit('tracking:update', coord)`.

## 6. Implementation Roadmap

*   **Phase 1: Project Initialization & Infrastructure Layer**
    *   Setting up Monorepo (or organized Multi-repo) folder structure.
*   **Phase 2: Core Unified Flutter App**
    *   Auth Flow, role separation, and routing based on Customer/Worker JWT claim.
    *   Integrate `camera` plugin for photos, and `geolocator` plugin for exact Coordinates.
*   **Phase 3: Backend & Database Schema**
    *   Express + TS scaffolding.
*   **Phase 4: AI Service Stubbing & Integration**
    *   Python FastAPI service.
*   **Phase 5: Real-time Comms & Finishing UI**
    *   Socket integrations. Map plotting for users and workers.
