# Perbedaan dengan versi sebelumnya

## Ringkasan
| | Versi sebelumnya (`projekCapston5`) | Versi ini (`gym-ai-app`) |
|---|---|---|
| Struktur | 1 proyek Flutter, semua layar di `lib/screens/` | 3 layanan: `mobile/`, `backend/`, `ai-service/` + `docs/` |
| Data | Data contoh tertulis di kode (hilang saat aplikasi ditutup) | Database SQLite lewat API (data tersimpan) |
| Login | Tombol "Masuk" langsung masuk tanpa cek | Login nyata (JWT), role MEMBER / TRAINER / ADMIN |
| Tampilan | Hitam-putih, kartu membulat | **Sama** (desain dipertahankan) |
| Cabang gym | Hanya dropdown di Beranda | Tab Gym: daftar, detail, fasilitas, paket |
| Booking PT | Belum ada dari sisi member | Member booking -> PT terima/tolak -> laporan sesi |
| Nutrisi AI | Belum ada | Layanan AI contoh (stub); belum terhubung ke aplikasi |

## Pemetaan file Flutter
| Sebelumnya | Sekarang | Perubahan |
|---|---|---|
| `main.dart` | `main.dart`, `app.dart`, `core/router/app_router.dart` | Router dan tema dipisah |
| `screens/splash_screen.dart` | `features/onboarding/.../splash_screen.dart` | Cek sesi tersimpan, langsung ke beranda sesuai role |
| `screens/login_screen.dart` | `features/authentication/.../login_screen.dart` | Login ke API, pesan error, tampil/sembunyi password |
| `screens/register_screen.dart` | `features/authentication/.../register_screen.dart` | Daftar ke API; PT memilih cabang; opsi Admin dihapus (admin dibuat sistem) |
| `screens/main_nav_screen.dart` | `features/dashboard/.../member_shell.dart` | Ditambah tab **Gym** |
| `screens/beranda_screen.dart` | `features/dashboard/.../member_home_screen.dart` | Cabang, paket, dan membership dari API; ditambah kartu "Sesi Saya" |
| `screens/latihan_screen.dart` | `features/exercises/.../exercises_screen.dart` | Tidak berubah (data statis) |
| `screens/profil_screen.dart` | `features/profile/.../member_profile_screen.dart` | Nama/email dari akun, riwayat latihan dari API, ubah data pribadi |
| `screens/trainer_list_screen.dart` | `features/personal_trainers/.../trainer_list_screen.dart` | Data PT dari API |
| `screens/trainer_detail_screen.dart` | `features/personal_trainers/.../trainer_detail_screen.dart` | Ditambah tombol **Booking Sesi Latihan** |
| `screens/trainer_chat_screen.dart` | `features/chat/.../trainer_chat_screen.dart` | Tidak berubah (balasan masih otomatis) |
| `screens/nutrition_plan_screen.dart` | `features/meal_plans/.../nutrition_plan_screen.dart` | Tidak berubah (data statis) |
| `screens/pt_dashboard_screen.dart` + `pt_profile_screen.dart` (dua class bentrok) | `features/dashboard/.../pt_dashboard_screen.dart`, `pt_home_tab.dart` | Satu dashboard 5 tab, statistik dari API |
| (tab Klien berisi placeholder) | `features/client_goals/.../pt_clients_tab.dart` | Pencarian, filter, bar progres |
| `screens/pt_client_detail_screen.dart` | `features/client_goals/.../pt_client_detail_screen.dart` | Target program dan nutrisi tersimpan ke server |
| `screens/pt_schedule_screen.dart` | `features/schedules/.../pt_schedule_screen.dart` | Jadwal tersimpan; pilih hari dan jam lewat picker |
| `screens/pt_session_management_screen.dart` | `features/bookings/.../pt_session_management_screen.dart` | Terima/tolak nyata, deteksi jadwal bentrok |
| `screens/pt_session_report_screen.dart` | `features/training_sessions/.../pt_session_report_screen.dart` | Laporan disimpan, booking jadi Selesai |
| `models/trainer_model.dart`, `models/app_data.dart` | dihapus | Diganti API + `SessionController` |

## Baru
- `features/gym_selection/` : daftar & detail cabang gym (dulu hanya dropdown).
- `features/memberships/` : beli paket dan status membership dari server.
- `features/bookings/` : booking sesi oleh member (`create_booking_screen`, `my_bookings_screen`).
- `features/admin_management/` : beranda Admin Gym (ubah info cabang miliknya).
- `core/` dan `shared/` : ApiClient, token storage, widget bersama (loading, error, empty state).
- `backend/` dan `ai-service/` : seluruhnya baru.

## Aturan bisnis baru (di backend)
- Booking PT terbuka untuk semua client, dengan atau tanpa membership.
- PT tidak bisa menerima dua sesi yang waktunya bertumpukan.
- Laporan sesi hanya untuk sesi berstatus Diterima, lalu sesi menjadi Selesai.
- Admin Gym hanya bisa mengubah cabangnya sendiri.
- Pendaftaran publik hanya untuk Member dan PT.

## Yang belum dikerjakan (tahap berikutnya)
Nutrisi (profil, scan, riwayat, kamus), rekomendasi makanan dan belanja di aplikasi, meal plan dari AI, chatbot AI, chat nyata, rating PT, notifikasi, tab Progress, pembayaran sungguhan. Folder-foldernya sudah disiapkan sesuai `struktur.txt`.


---

# Tambahan: Website Admin (`admin-web/`)

Baru: website React + Vite + TypeScript + react-hot-toast untuk pemilik gym, **tanpa super admin**.

| Bagian | Perubahan |
|---|---|
| `admin-web/` (baru) | Landing page, daftar gym, login admin, dashboard, kelola cabang/PT/member/booking |
| Backend `POST /gym-applications` | Daftar pemilik + gym (multipart, foto fasilitas); langsung aktif, tanpa persetujuan; batas 10 pendaftaran/jam/IP |
| Backend `/admin/*` | Dashboard & CRUD, otomatis dibatasi ke cabang admin tersebut |
| Skema DB | `User.birthPlace/birthDate`, `TrainerProfile.isActive`, tabel baru `GymImage` |
| PT nonaktif | Hilang dari daftar PT di aplikasi, tidak bisa dibooking; riwayat tetap ada |
| Mobile | `NetworkThumb` memahami path `/uploads/...`; detail gym menampilkan galeri foto; gym tanpa foto memakai ikon |
| Tes | 22 tes e2e (9 baru untuk website/admin, termasuk isolasi antar-cabang) |

**Penting bila Anda sudah punya `dev.db`:** skema berubah, jalankan ulang `npx prisma db push` di `backend/`
(atau `npm run setup` untuk membuat ulang database beserta data contoh — ini menghapus isi lama).


---

# Tambahan: Paket tujuan & pola makan per klien

| Bagian | Perubahan |
|---|---|
| Booking | Member memilih **paket tujuan** (turun berat badan, naik massa otot, toning, stamina, pemulihan cedera, kebugaran umum). Tampil di Sesi Saya, permintaan booking PT, kartu klien PT, dan tabel booking website admin |
| Pola makan (backend) | Tabel baru `MealPlanItem`. `GET /meal-plans/me` untuk member (id dari token, tidak bisa melihat milik orang lain); PT: `GET/POST /meal-plans/client/:clientId`, `PATCH/DELETE /meal-plans/:id` |
| Pola makan (Flutter) | `NutritionPlanScreen` sekarang khusus member yang login (baca saja, data dari server). Layar baru `PtClientNutritionScreen`: PT menambah/ubah/hapus menu **satu klien**. Data statis dan tombol ganti role dihapus |
| Dashboard PT | Tombol "Menu Klien" membawa ke tab Klien: menu & nutrisi hanya bisa dibuka dari klien tertentu |
| Data contoh | Andra jadi klien Alex (tujuan naik massa otot) dengan 4 menu; Budi punya 3 menu berbeda |
| Tes | 27 tes e2e (5 baru: isolasi menu antar-member, CRUD PT, PT lain ditolak, tujuan booking) |

Skema berubah lagi (`Booking.goalType`, tabel `MealPlanItem`): jalankan `npx prisma db push`, atau `npm run setup` untuk reset dengan data contoh baru.


## Program latihan dari PT, log progres, dan aktivitas di Beranda
- **Program latihan**: PT menyusun gerakan per klien (Profil Klien > Kelola Program Latihan).
  Klien melihatnya di tab *Latihan* dan bisa mencentang gerakan yang sudah dikerjakan.
  Endpoint: `GET /workout-plans/me`, `POST/DELETE /workout-plans/me/:itemId/done` (member);
  `GET/POST /workout-plans/client/:clientId`, `PATCH/DELETE /workout-plans/:id` (PT).
- **Progress**: tab *Progress* menampilkan log aktivitas (`GET /activity/me`): pembelian membership,
  booking PT, sesi selesai, dan gerakan yang dicentang, plus ringkasan angka.
- **Beranda**: kotak *Aktivitas Terbaru* (5 entri) di bawah kartu membership.
- Tombol back ditambahkan di layar Latihan dan Progress.
- Perubahan skema: model `WorkoutPlanItem` & `WorkoutLog`, kolom `GymMembership.createdAt`,
  `Booking.updatedAt`. Jalankan `npm run setup` (generate + db push + seed) di folder backend.


## Kuota 8 sesi PT, jadwal dari PT, dan tujuan bebas
- **Kuota sesi**: setiap pasangan klien-PT punya paket 8 sesi (`SessionPackage`, default sama untuk semua PT).
  Sisa sesi = kuota - sesi berstatus COMPLETED. Sesi yang menunggu/terjadwal juga menahan jatah booking baru.
  Kuota habis -> booking baru ditolak sampai PT menambah kuota.
- **Tampilan user**: "Sisa sesi: x dari 8" di layar booking dan kotak kecil di Beranda.
- **PT**: di Profil Klien ada kartu kuota, tombol *Jadwalkan Sesi* (pilih hari + jam, langsung ACCEPTED,
  memotong jatah) dan *Tambah Kuota*. Pilihan hari program latihan menjadi Hari 1-8.
- **Tujuan bebas**: kolom teks opsional "Tujuan lain / program yang diinginkan" saat booking (`Booking.customGoal`),
  tampil di kartu booking dan Profil Klien PT.
- Endpoint: `GET /session-packages/me`, `GET /session-packages/me/trainer/:trainerId` (member);
  `GET /session-packages/client/:clientId`, `POST /session-packages/client/:clientId/add`,
  `POST /bookings/trainer/schedule` (PT).
- Perubahan skema: model `SessionPackage`, kolom `Booking.customGoal`. Jalankan `npm run setup` di backend.
