# Windows setup — Botad Bus Tracker

Run **one command per line** in Command Prompt or PowerShell. Do not paste comments (`# ...`) into the terminal.

---

## Problem you saw

```
Broadcast error: connect ECONNREFUSED 127.0.0.1:27017
```

**Meaning:** MongoDB is not running on your PC. The API needs a database before `npm run dev` will work fully.

---

## Option A — MongoDB Atlas (recommended, no local install)

1. Go to https://www.mongodb.com/cloud/atlas and create a free cluster.
2. Database Access → add a user (username + password).
3. Network Access → Add IP → **Allow Access from Anywhere** (for dev) or your IP.
4. Connect → Drivers → copy the connection string, e.g.  
   `mongodb+srv://USER:PASSWORD@cluster0.xxxxx.mongodb.net/botad-bus-tracker`
5. Edit `backend\.env`:

```env
MONGODB_URI=mongodb+srv://USER:PASSWORD@cluster0.xxxxx.mongodb.net/botad-bus-tracker
```

6. In the **backend** folder:

```bat
cd /d "d:\app\botad bus system\botad-bus-tracker\backend"
npm run seed
npm run dev
```

---

## Option B — MongoDB on Windows (local)

1. Install: https://www.mongodb.com/try/download/community  
   Choose **Windows** → MSI → include **MongoDB as a Service**.
2. Open **Services** (`Win+R` → `services.msc`) → find **MongoDB** → **Start**.
3. Keep `backend\.env` as:

```env
MONGODB_URI=mongodb://127.0.0.1:27017/botad-bus-tracker
```

4. Seed and run:

```bat
cd /d "d:\app\botad bus system\botad-bus-tracker\backend"
npm run seed
npm run dev
```

---

## Backend (terminal 1)

```bat
cd /d "d:\app\botad bus system\botad-bus-tracker\backend"
npm install
npm run seed
npm run dev
```

You should see:

```
MongoDB connected: ...
Botad Bus Tracker API running on port 5000
```

Open http://localhost:5000/health in the browser.

---

## Frontend (terminal 2 — new window)

```bat
cd /d "d:\app\botad bus system\botad-bus-tracker\frontend"
npm install
copy .env.example .env
npm run dev
```

Edit `frontend\.env`:

```env
VITE_BACKEND_URL=http://localhost:5000
VITE_SOCKET_URL=http://localhost:5000
VITE_GOOGLE_MAPS_KEY=your_key_here
```

Open http://localhost:3000

---

## Common mistakes

| Mistake | Fix |
|--------|-----|
| `npm run devcd "d:\...\frontend"` | Two commands: `npm run dev` then `cd ...` in a **new** terminal |
| `# Copy .env.example` in cmd | `#` is a comment — use `copy .env.example .env` |
| API runs but spam errors | Start MongoDB or use Atlas URI in `.env` |
| `npm run seed` fails | Fix `MONGODB_URI` first, then seed again |

---

## Test logins (after `npm run seed`)

| Role | Phone | Password |
|------|-------|----------|
| Admin | 9999999999 | admin123 |
| Driver | 9876543210 | driver123 |
