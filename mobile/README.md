# GymFit Mobile (Flutter)

Aplikasi member, Personal Trainer, dan Admin Gym. Terhubung ke `../backend`.

## Menjalankan
```bash
cd mobile
flutter pub get
flutter analyze
flutter test
flutter run                                   # emulator Android -> otomatis ke http://10.0.2.2:3000
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:3000   # HP asli / alamat lain
```
Pastikan backend sudah berjalan (lihat `../backend/README.md`).

## Struktur
- `lib/core` : konfigurasi, jaringan (ApiClient), router, tema, penyimpanan token, util.
- `lib/shared` : widget & model yang dipakai banyak fitur.
- `lib/features/<fitur>/{data,domain,presentation}` : satu folder per fitur.
  Folder fitur yang belum dikerjakan (nutrisi, scan makanan, dsb.) masih kosong (`.gitkeep`).

## Akun demo (setelah seed backend, password `password123`)
Member `andra.setya@email.com` - PT `alex.pt@gymfit.com` - Admin `admin@gymfit.com`
