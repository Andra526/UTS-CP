# Desain database (Prisma, `backend/prisma/schema.prisma`)

| Tabel | Isi penting |
|---|---|
| User | name, email (unik), phone, passwordHash, role, managedGymId (admin) |
| Gym | name (unik), city, address, openHours, phone, imageUrl, rating, memberCount |
| GymFacility / GymPlan | fasilitas; paket (price, durationDays, isPopular) |
| GymMembership | user, gym, plan, price, startDate, endDate, status |
| TrainerProfile | user (unik), gym, specialization, experienceYears, bio, rating |
| TrainerSchedule | trainer, day, startTime, endTime |
| Booking | client, trainer, scheduledAt, durationMin, status (PENDING/ACCEPTED/REJECTED/COMPLETED/CANCELLED) |
| TrainingSession | booking (unik), attendance, intensity 1-10, notes |
| ClientGoal | client + trainer (unik), description, targetCalories, targetProtein |

Catatan: SQLite dipakai untuk pengembangan. Nilai role/status disimpan sebagai teks dan divalidasi di aplikasi.
Jika `schema.prisma` berubah, perbarui juga `backend/test/test-schema.sql` yang dipakai tes.
