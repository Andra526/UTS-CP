# Dokumentasi API

Semua endpoint (kecuali yang bertanda publik) memerlukan header `Authorization: Bearer <token>`.
Tabel endpoint lengkap ada di `backend/README.md`.

## Contoh
```bash
# Login
curl -X POST localhost:3000/auth/login -H 'Content-Type: application/json' \
  -d '{"identifier":"andra.setya@email.com","password":"password123"}'

# Daftar gym (publik)
curl localhost:3000/gyms

# Booking sesi (member, tanpa syarat membership)
curl -X POST localhost:3000/bookings -H "Authorization: Bearer $TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{"trainerId":"<id>","scheduledAt":"2026-11-02T07:00:00.000Z","durationMin":60}'
```

## Kode error umum
400 data tidak valid - 401 token salah/kedaluwarsa - 403 role tidak boleh - 404 tidak ditemukan - 409 konflik (email ganda, jadwal bentrok, sesi sudah dilaporkan).

## AI service (port 8000)
Lihat `ai-service/README.md`. Dokumentasi interaktif: `http://localhost:8000/docs`.
