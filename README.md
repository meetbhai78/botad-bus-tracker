# Botad Bus Tracker

Real-time bus tracking for **Botad City, Gujarat, India**.

## Stack

| Layer | Tech |
|-------|------|
| Backend | Node.js, Express, Socket.io, MongoDB |
| Web | React (Vite), Tailwind, Google Maps |
| Mobile | Flutter (driver + passenger) |
| ETA | Python FastAPI |

## Roles (GRTC-style · startup UI)

| Role | Where | What they do |
|------|--------|----------------|
| **Admin** | Web `/admin` | Add **bus stops** (name + lat/lng), build **routes**, update **timetable**, view **drivers & passengers** |
| **Driver** | Flutter `driver-app` | Login, start trip, GPS live tracking |
| **Passenger** | Flutter `passenger-app` | **Register / login**, search routes, timetable, book ticket, live map |

**Seed logins** (after `npm run seed` in `backend`):

- Admin: `9999999999` / `admin123` → http://localhost:3000/login → Admin Console  
- Driver: `9876543210` / `driver123`  
- Passenger: `9123456789` / `pass123`  

## Quick start

### 1. Backend

```bash
cd backend
cp .env.example .env
# Edit MONGODB_URI and JWT_SECRET
npm install
npm run seed
npm run dev
```

API: `http://localhost:5000` · Health: `GET /health`

### 2. Frontend

```bash
cd frontend
cp .env.example .env
# VITE_GOOGLE_MAPS_KEY, VITE_BACKEND_URL, VITE_SOCKET_URL
npm install
npm run dev
```

Open `http://localhost:3000` — passenger map · `/admin` — dashboard

### 3. AI ETA

```bash
cd ai-eta
pip install -r requirements.txt
uvicorn main:app --reload --port 8000
```

### 4. Flutter

```bash
cd driver-app   # or passenger-app
flutter pub get

# Run with environment variables for URLs and API Keys
# Default API_BASE_URL is http://10.0.2.2:5000 (Android Emulator)
# Use your computer's LAN IP (e.g. 192.168.1.x) for physical devices
flutter run --dart-define=API_BASE_URL=http://YOUR_LAN_IP:5000 --dart-define=MAPTILER_KEY=your_key_here
```

## Project layout

```
botad-bus-tracker/
├── backend/       # REST + Socket.io
├── frontend/      # React web
├── driver-app/    # Flutter driver
├── passenger-app/ # Flutter passenger
└── ai-eta/        # ETA microservice
```

## API & Socket Events (Must Match)

**Canonical Route API:** The React Admin UI uses `POST /api/admin/routes` to build routes using `stops` array. `POST /api/routes` is deprecated.
**Legacy Admin UI:** `backend/public/index.html` is deprecated. Use the React admin panel.

- Client → `driver:location`, `passenger:watch`, `passenger:watchStop`
- Server → `buses:locations` (global list, every 3s), `bus:update` (single bus), `stop:eta` (per-stop ETAs)

## Deploy

- Backend → Render.com
- Frontend → Vercel
- DB → MongoDB Atlas
- Set `CORS_ORIGINS` to your Vercel URL

---

*Built from `botad_bus_tracker_prompt.md` for Botad, Gujarat.*
