# GymFit Backend (NestJS + Prisma + SQLite)

## Menjalankan
```bash
cd backend
npm install
cp .env.example .env
npm run setup        # prisma generate + db push + seed data demo
npm run start:dev    # http://localhost:3000
```
Akun demo (password: `password123`): `andra.setya@email.com` (member), `alex.pt@gymfit.com` (PT), `admin@gymfit.com` (admin).

## Tes
```bash
npm test
```
Tes e2e memakai database SQLite sementara (`test/test-schema.sql`).
Jika `prisma/schema.prisma` diubah, perbarui `test/test-schema.sql` agar sama.

## Endpoint utama
| Method | Path | Role | Keterangan |
|---|---|---|---|
| POST | /auth/register, /auth/login | publik | daftar (MEMBER/TRAINER) & login |
| GET | /auth/me, /users/me | semua | profil |
| GET | /gyms, /gyms/:id | publik | daftar & detail cabang |
| PATCH | /gyms/:id | ADMIN (cabangnya) | ubah info cabang |
| POST | /memberships | MEMBER | beli paket (pembayaran simulasi) |
| GET | /memberships/me, /memberships/me/active | MEMBER | membership |
| GET | /trainers?gymId= | semua | daftar PT |
| GET | /trainers/me/dashboard | TRAINER | ringkasan dashboard |
| GET/POST/DELETE | /trainer-schedules | TRAINER | jadwal ketersediaan |
| GET | /clients | TRAINER | daftar klien |
| POST | /bookings | MEMBER | request sesi (tidak perlu membership); `goalType` = WEIGHT_LOSS, MUSCLE_GAIN, TONING, ENDURANCE, REHAB, GENERAL |
| GET | /bookings/me, /bookings/trainer | MEMBER / TRAINER | daftar booking |
| PATCH | /bookings/:id/status, /cancel | TRAINER / MEMBER | terima, tolak, batalkan |
| POST | /training-sessions | TRAINER | laporan sesi (booking jadi COMPLETED) |
| GET | /training-sessions/me | MEMBER | riwayat latihan |
| GET/PUT | /client-goals/:clientId | MEMBER, TRAINER | target program & nutrisi |
| GET | /meal-plans/me | MEMBER | pola makan milik akun yang login (tanpa parameter id) |
| GET/POST | /meal-plans/client/:clientId | TRAINER | lihat / tambah menu satu klien (hanya klien PT tsb) |
| PATCH/DELETE | /meal-plans/:id | TRAINER | ubah / hapus menu buatannya |
| GET | /health | publik | cek server & database |
| POST | /gym-applications | publik (multipart) | website: daftar pemilik + gym baru (+ foto `images`), langsung aktif, mengembalikan token |
| GET | /admin/dashboard | ADMIN | member aktif, PT, sesi minggu ini, pendapatan |
| GET/PATCH | /admin/gym | ADMIN | info cabang |
| POST/PATCH/DELETE | /admin/gym/facilities(/:id), /admin/gym/plans(/:id) | ADMIN | fasilitas & paket harga |
| POST/DELETE | /admin/gym/images(/:id) | ADMIN | foto fasilitas (JPG/PNG/WEBP, maks 3 MB) |
| GET/POST/PATCH/DELETE | /admin/trainers(/:id) | ADMIN | kelola PT; `isActive:false` = nonaktif |
| GET/POST/PATCH/DELETE | /admin/memberships(/:id) | ADMIN | daftar member + status, daftarkan manual |
| GET/PATCH/DELETE | /admin/bookings(/:id) | ADMIN | booking & laporan sesi |

Semua `/admin/*` otomatis dibatasi ke cabang milik admin (`gymId` di token). Foto disimpan di folder `uploads/`
(ubah dengan env `UPLOAD_DIR`) dan dilayani di `/uploads/<file>`; database hanya menyimpan path-nya.

## Pindah ke PostgreSQL
Ubah `provider` di `schema.prisma`, pasang `@prisma/adapter-pg`, dan ganti adapter di `src/database/prisma/prisma.service.ts` serta `prisma/seed.ts`.
