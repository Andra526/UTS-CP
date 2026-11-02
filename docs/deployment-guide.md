# Deployment (ringkas)

- **Backend**: `npm run build` lalu `npm run start:prod`. Untuk produksi pindah ke PostgreSQL, set `JWT_SECRET` yang kuat, dan batasi CORS di `main.ts`.
- **AI service**: `uvicorn app.main:app --host 0.0.0.0 --port 8000` di belakang reverse proxy.
- **Mobile**: set `--dart-define=API_BASE_URL=https://api.domain-anda.com`. Produksi wajib HTTPS; hapus `usesCleartextTraffic` di `AndroidManifest.xml`.
