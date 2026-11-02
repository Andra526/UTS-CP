# GymFit AI App

Aplikasi gym + personal trainer + nutrisi AI.

| Folder | Isi | Teknologi |
|---|---|---|
| `mobile/` | Aplikasi Member / PT / Admin | Flutter |
| `admin-web/` | Website pemilik gym (landing, daftar gym, dashboard admin) | React + Vite + TypeScript |
| `backend/` | REST API, login, booking, membership | NestJS + Prisma + SQLite |
| `ai-service/` | Layanan AI (saat ini hasil contoh/stub) | Python FastAPI |
| `docs/` | Dokumentasi | Markdown |

## Mulai cepat
1. Backend: `cd backend && npm install && cp .env.example .env && npm run setup && npm run start:dev`
2. AI service (opsional): `cd ai-service && pip install -r requirements.txt && uvicorn app.main:app --port 8000`
3. Mobile: `cd mobile && flutter pub get && flutter run`

Detail ada di `docs/setup-guide.md`.
