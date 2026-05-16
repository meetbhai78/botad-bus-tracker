# Botad Bus Tracker

Real-time bus tracking for **Botad City, Gujarat, India**.

## Stack

| Layer | Tech |
|-------|------|
| Backend | Node.js, Express, Socket.io, MongoDB |
| Web | React (Vite), Tailwind, Google Maps |
| Mobile | Flutter (driver + passenger) |
| ETA | Python FastAPI |

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

**Seed logins**

| Role | Phone | Password |
|------|-------|----------|
| Admin | 9999999999 | admin123 |
| Driver | 9876543210 | driver123 |

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
# Set API URL in lib/constants.dart (use LAN IP on real device)
flutter run
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

## Socket events (must match)

- Client → `driver:location`, `passenger:watch`, `passenger:watchStop`
- Server → `buses:locations` (every 3s), `bus:update`, `stop:eta`

## Deploy

- Backend → Render.com
- Frontend → Vercel
- DB → MongoDB Atlas
- Set `CORS_ORIGINS` to your Vercel URL

---

*Built from `botad_bus_tracker_prompt.md` for Botad, Gujarat.*
