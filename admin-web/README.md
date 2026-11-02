# GymFit Admin Web

Website untuk pemilik gym: landing page, daftar gym baru, login admin per cabang, dan dashboard.
Stack: React 19 + Vite + TypeScript + react-router + react-hot-toast (CSS biasa, tanpa framework CSS).

Website **tidak punya database sendiri**. Semua data lewat backend NestJS yang sama dengan aplikasi HP,
jadi gym yang didaftarkan di sini otomatis muncul di aplikasi (`GET /gyms`). Tidak ada super admin:
setiap pendaftaran langsung aktif dan membuat akun admin untuk cabang itu.

## Menjalankan
```bash
# 1) backend harus jalan dulu (lihat ../backend/README.md), default http://localhost:3000
cd admin-web
npm install
cp .env.example .env     # ubah VITE_API_URL bila backend di alamat lain
npm run dev              # http://localhost:5173
npm run build            # hasil produksi di dist/
```

## Halaman
| Path | Isi |
|---|---|
| `/` | Landing page |
| `/daftar` | Daftar gym: nama, tempat & tanggal lahir, email, nama gym, lokasi, foto fasilitas |
| `/masuk` | Login admin |
| `/admin` | Ringkasan: member aktif, PT, sesi minggu ini, pendapatan membership |
| `/admin/cabang` | Info, fasilitas, paket harga, foto (CRUD) |
| `/admin/trainer` | Tambah, ubah, nonaktifkan/aktifkan, hapus PT |
| `/admin/member` | Daftar member + status membership, daftarkan/akhiri/hapus |
| `/admin/booking` | Booking & laporan sesi, batalkan/hapus |
