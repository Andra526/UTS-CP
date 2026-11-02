# Arsitektur

```
Flutter (mobile)  --HTTP/JSON + JWT-->  NestJS (backend)  --Prisma-->  SQLite
                                              |
                                              +--HTTP--> FastAPI (ai-service)   [belum dipanggil di tahap 1]
```

- **mobile**: `ApiClient` menambahkan token ke setiap request. Jika server menjawab 401, sesi dihapus dan pengguna kembali ke login.
- **backend**: JWT guard global, `@Public()` untuk endpoint terbuka, `@Roles()` + RolesGuard untuk pembatasan role, TenantGuard untuk pembatasan per cabang.
- **ai-service**: layanan terpisah supaya model Python bisa diganti tanpa menyentuh backend.

## Peran
| Role | Bisa |
|---|---|
| MEMBER | lihat gym/PT, beli membership, booking & batalkan sesi, lihat riwayat |
| TRAINER | dashboard, klien, jadwal, terima/tolak request, laporan sesi, target klien |
| ADMIN | ubah info cabang yang dikelola |
