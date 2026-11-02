import 'dotenv/config';
import { PrismaBetterSqlite3 } from '@prisma/adapter-better-sqlite3';
import * as bcrypt from 'bcryptjs';
import { PrismaClient } from '../src/generated/client';

const prisma = new PrismaClient({
  adapter: new PrismaBetterSqlite3({
    url: process.env.DATABASE_URL ?? 'file:./dev.db',
  }),
});

const DEMO_PASSWORD = 'password123';
const HOUR = 60 * 60 * 1000;
const DAY = 24 * HOUR;

function at(daysFromNow: number, hour: number) {
  const d = new Date(Date.now() + daysFromNow * DAY);
  d.setHours(hour, 0, 0, 0);
  return d;
}

const baseFacilities = [
  { label: 'Free Weight', icon: 'fitness_center' },
  { label: 'Cardio Area', icon: 'directions_run' },
  { label: 'Locker', icon: 'lock_outline' },
  { label: 'Shower', icon: 'shower_outlined' },
  { label: 'Wi-Fi', icon: 'wifi' },
];

// Harga Bulanan/Tahunan mengikuti layar Beranda aplikasi sebelumnya
// (Rp 250rb dan Rp 2,4jt). Paket Harian adalah tambahan.
const basePlans = [
  { name: 'Harian', price: 50000, durationDays: 1, note: 'Akses semua area gym', isPopular: false },
  { name: 'Bulanan', price: 250000, durationDays: 30, note: 'Akses penuh + 1x sesi orientasi PT', isPopular: true },
  { name: 'Tahunan', price: 2400000, durationDays: 365, note: 'Hemat + 2x konsultasi nutrisi', isPopular: false },
];

async function main() {
  // Reset (urutan mengikuti relasi)
  await prisma.sessionPackage.deleteMany();
  await prisma.workoutLog.deleteMany();
  await prisma.workoutPlanItem.deleteMany();
  await prisma.mealPlanItem.deleteMany();
  await prisma.trainingSession.deleteMany();
  await prisma.clientGoal.deleteMany();
  await prisma.booking.deleteMany();
  await prisma.trainerSchedule.deleteMany();
  await prisma.gymMembership.deleteMany();
  await prisma.trainerProfile.deleteMany();
  await prisma.user.deleteMany();
  await prisma.gymPlan.deleteMany();
  await prisma.gymFacility.deleteMany();
  await prisma.gymImage.deleteMany();
  await prisma.gym.deleteMany();

  const passwordHash = await bcrypt.hash(DEMO_PASSWORD, 10);

  // ---------- Gym
  const gymsData = [
    {
      name: 'GymFit Sudirman, Jakarta Pusat',
      city: 'Jakarta Pusat',
      address: 'Jl. Jend. Sudirman Kav. 25, Jakarta Pusat',
      openHours: '05:00 - 23:00 WIB',
      phone: '021-5550-1001',
      imageUrl: 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=800',
      rating: 4.8,
      memberCount: 1240,
      extra: [
        { label: 'Studio Yoga', icon: 'self_improvement' },
        { label: 'Sauna', icon: 'hot_tub_outlined' },
      ],
    },
    {
      name: 'GymFit Boulevard, Kelapa Gading',
      city: 'Jakarta Utara',
      address: 'Boulevard Raya Blok FA 3, Kelapa Gading',
      openHours: '06:00 - 22:00 WIB',
      phone: '021-5550-2002',
      imageUrl: 'https://images.unsplash.com/photo-1571902943202-507ec2618e8f?w=800',
      rating: 4.6,
      memberCount: 860,
      extra: [{ label: 'Studio Yoga', icon: 'self_improvement' }],
    },
    {
      name: 'GymFit Pasteur, Bandung',
      city: 'Bandung',
      address: 'Jl. Dr. Djunjunan No. 88, Pasteur, Bandung',
      openHours: '06:00 - 22:00 WIB',
      phone: '022-5550-3003',
      imageUrl: 'https://images.unsplash.com/photo-1540497077202-7c8a3999166f?w=800',
      rating: 4.7,
      memberCount: 640,
      extra: [{ label: 'Area CrossFit', icon: 'sports_gymnastics' }],
    },
  ];

  const gyms: Record<string, { id: string; plans: { id: string; name: string }[] }> = {};
  for (const g of gymsData) {
    const { extra, ...data } = g;
    const created = await prisma.gym.create({
      data: {
        ...data,
        facilities: { create: [...baseFacilities, ...extra] },
        plans: { create: basePlans },
      },
      include: { plans: true },
    });
    gyms[g.name] = { id: created.id, plans: created.plans };
  }
  const sudirman = gyms['GymFit Sudirman, Jakarta Pusat'];
  const boulevard = gyms['GymFit Boulevard, Kelapa Gading'];
  const pasteur = gyms['GymFit Pasteur, Bandung'];

  // ---------- Admin Gym
  await prisma.user.create({
    data: {
      name: 'Admin GymFit Sudirman',
      email: 'admin@gymfit.com',
      passwordHash,
      role: 'ADMIN',
      managedGymId: sudirman.id,
    },
  });

  // ---------- Trainer (dari data aplikasi sebelumnya)
  const trainersData = [
    { name: 'Alex Pratama, S.Or.', email: 'alex.pt@gymfit.com', gym: sudirman, spec: 'Hypertrophy & Bodybuilding', years: 6, rating: 4.9, reviews: 128, photo: 'photo-1568602471122-7832951cc4c5', bio: 'Spesialis dalam pembentukan otot dan penambahan massa tubuh dengan metode scientific lifting.' },
    { name: 'Sarah Wijaya', email: 'sarah.pt@gymfit.com', gym: sudirman, spec: 'Weight Loss & Tone', years: 5, rating: 4.8, reviews: 94, photo: 'photo-1534528741775-53994a69daeb', bio: 'Membantu menurunkan berat badan secara sehat, menjaga postur tubuh, serta membentuk otot lean.' },
    { name: 'Riki Santoso', email: 'riki.pt@gymfit.com', gym: boulevard, spec: 'Functional & Strength', years: 7, rating: 4.7, reviews: 82, photo: 'photo-1507003211169-0a1dd7228f2d', bio: 'Fokus pada kekuatan fungsional, kelenturan sendi, dan pencegahan cedera saat berolahraga.' },
    { name: 'Dewi Lestari', email: 'dewi.pt@gymfit.com', gym: boulevard, spec: 'Yoga & Core Stability', years: 4, rating: 4.9, reviews: 110, photo: 'photo-1517841905240-472988babdf9', bio: 'Menggabungkan teknik pernapasan yoga dengan core workout untuk postur tubuh yang ideal.' },
    { name: 'Michael Gunawan', email: 'michael.pt@gymfit.com', gym: pasteur, spec: 'CrossFit & Athletic', years: 5, rating: 4.6, reviews: 76, photo: 'photo-1500648767791-00dcc994a43e', bio: 'Meningkatkan daya tahan tubuh, kecepatan, dan ketahanan fisik maksimal dengan intensitas tinggi.' },
  ];
  const trainers: Record<string, string> = {}; // email -> trainerProfile.id
  for (const t of trainersData) {
    const user = await prisma.user.create({
      data: {
        name: t.name,
        email: t.email,
        passwordHash,
        role: 'TRAINER',
        photoUrl: `https://images.unsplash.com/${t.photo}?w=400`,
        trainerProfile: {
          create: {
            gymId: t.gym.id,
            specialization: t.spec,
            experienceYears: t.years,
            bio: t.bio,
            rating: t.rating,
            reviewsCount: t.reviews,
          },
        },
      },
      include: { trainerProfile: true },
    });
    trainers[t.email] = user.trainerProfile!.id;
  }
  const alex = trainers['alex.pt@gymfit.com'];

  // ---------- Jadwal Alex
  await prisma.trainerSchedule.createMany({
    data: [
      { trainerId: alex, day: 'Senin', startTime: '09:00', endTime: '11:00' },
      { trainerId: alex, day: 'Selasa', startTime: '13:00', endTime: '16:00' },
      { trainerId: alex, day: 'Rabu', startTime: '09:00', endTime: '12:00' },
      { trainerId: alex, day: 'Jumat', startTime: '14:00', endTime: '18:00' },
    ],
  });

  // ---------- Member
  const memberData = [
    { name: 'Andra Setya R.', email: 'andra.setya@email.com', plan: 'Tahunan', photo: null as string | null },
    { name: 'Budi Santoso', email: 'budi@email.com', plan: 'Bulanan', photo: 'photo-1534528741775-53994a69daeb' },
    { name: 'Siti Rahma', email: 'siti@email.com', plan: 'Bulanan', photo: 'photo-1517841905240-472988babdf9' },
    { name: 'Joko Anwar', email: 'joko@email.com', plan: 'Bulanan', photo: 'photo-1507003211169-0a1dd7228f2d' },
  ];
  const members: Record<string, string> = {};
  for (const m of memberData) {
    const user = await prisma.user.create({
      data: {
        name: m.name,
        email: m.email,
        passwordHash,
        role: 'MEMBER',
        photoUrl: m.photo ? `https://images.unsplash.com/${m.photo}?w=400` : null,
      },
    });
    members[m.email] = user.id;

    const plan = sudirman.plans.find((p) => p.name === m.plan)!;
    const days = m.plan === 'Tahunan' ? 365 : 30;
    await prisma.gymMembership.create({
      data: {
        userId: user.id,
        gymId: sudirman.id,
        planId: plan.id,
        price: m.plan === 'Tahunan' ? 2400000 : 250000,
        startDate: new Date(Date.now() - 5 * DAY),
        endDate: new Date(Date.now() + (days - 5) * DAY),
      },
    });
  }

  // ---------- Booking & sesi untuk Alex
  const budi = members['budi@email.com'];
  const siti = members['siti@email.com'];
  const joko = members['joko@email.com'];

  const past = await prisma.booking.create({
    data: { clientId: budi, trainerId: alex, scheduledAt: at(-2, 14), status: 'COMPLETED', note: 'Fat loss - sesi 1', goalType: 'WEIGHT_LOSS' },
  });
  await prisma.trainingSession.create({
    data: { bookingId: past.id, attendance: 'HADIR', intensity: 8, notes: 'Performa bagus, naikkan beban squat minggu depan.' },
  });
  await prisma.booking.create({
    data: { clientId: budi, trainerId: alex, scheduledAt: at(1, 14), status: 'ACCEPTED', note: 'Fat loss - sesi 2', goalType: 'WEIGHT_LOSS' },
  });
  await prisma.booking.create({
    data: { clientId: joko, trainerId: alex, scheduledAt: at(1, 16), status: 'ACCEPTED', note: 'Strength & conditioning', goalType: 'ENDURANCE' },
  });
  await prisma.booking.create({
    data: { clientId: siti, trainerId: alex, scheduledAt: at(2, 10), status: 'PENDING', note: 'Muscle gain - sesi pertama', goalType: 'MUSCLE_GAIN' },
  });

  await prisma.clientGoal.create({
    data: {
      clientId: budi,
      trainerId: alex,
      description: 'Turun 3 kg / lingkar perut berkurang 4 cm dalam 8 minggu',
      targetCalories: 2800,
      targetProtein: 180,
    },
  });

  // Andra (akun demo utama) juga klien Alex, dengan tujuan naik massa otot.
  const andra = members['andra.setya@email.com'];
  await prisma.booking.create({
    data: { clientId: andra, trainerId: alex, scheduledAt: at(3, 9), status: 'ACCEPTED', note: 'Bulking - sesi pertama', goalType: 'MUSCLE_GAIN' },
  });
  await prisma.clientGoal.create({
    data: { clientId: andra, trainerId: alex, description: 'Naik 4 kg massa otot dalam 12 minggu', targetCalories: 3000, targetProtein: 190 },
  });

  // Pola makan per klien (berbeda antar klien: bukti tiap member hanya melihat miliknya).
  const meals = (clientId: string, rows: [string, string, string, number, number][]) =>
    prisma.mealPlanItem.createMany({
      data: rows.map(([time, category, description, calories, protein]) => ({
        clientId, trainerId: alex, time, category, description, calories, protein,
      })),
    });
  await meals(andra, [
    ['07:30', 'Sarapan', '4 butir telur rebus, 80g oatmeal, 1 apel', 560, 38],
    ['12:30', 'Makan Siang', '200g dada ayam fillet, 150g nasi merah, brokoli kukus', 610, 54],
    ['16:30', 'Snack Sore', '200g greek yogurt, 1 sdm madu, 1 pisang', 320, 22],
    ['20:00', 'Makan Malam', '150g daging sapi tenderloin, kentang panggang, 1 scoop whey', 720, 52],
  ]);
  await meals(budi, [
    ['07:00', 'Sarapan', '2 telur rebus, 1 tangkap roti gandum, 1 jeruk', 380, 22],
    ['12:30', 'Makan Siang', '150g ikan dori panggang, 100g nasi merah, salad sayur', 470, 40],
    ['19:00', 'Makan Malam', 'Sup ayam tanpa kulit, tumis bayam, tahu kukus', 420, 38],
  ]);

  // Kuota sesi: semua pasangan klien-PT mendapat 8 sesi (default sistem).
  const pairs = new Set<string>();
  for (const b of await prisma.booking.findMany({ select: { clientId: true, trainerId: true } })) {
    pairs.add(`${b.clientId}|${b.trainerId}`);
  }
  await prisma.sessionPackage.createMany({
    data: [...pairs].map((k) => {
      const [clientId, trainerId] = k.split('|');
      return { clientId, trainerId, totalSessions: 8 };
    }),
  });

  // Program latihan per klien (disusun PT Alex).
  const workouts = (clientId: string, rows: [string, string, number, string, number][]) =>
    prisma.workoutPlanItem.createMany({
      data: rows.map(([dayLabel, exercise, sets, reps, restSec], position) => ({
        clientId, trainerId: alex, dayLabel, exercise, sets, reps, restSec, position,
      })),
    });
  await workouts(andra, [
    ['Hari 1 - Dada & Triceps', 'Bench Press', 4, '8-10', 90],
    ['Hari 1 - Dada & Triceps', 'Incline Dumbbell Press', 3, '10-12', 75],
    ['Hari 1 - Dada & Triceps', 'Triceps Pushdown', 3, '12-15', 60],
    ['Hari 2 - Punggung & Biceps', 'Lat Pulldown', 4, '10-12', 75],
    ['Hari 2 - Punggung & Biceps', 'Barbell Row', 3, '8-10', 90],
    ['Hari 2 - Punggung & Biceps', 'Dumbbell Curl', 3, '12', 60],
  ]);
  await workouts(budi, [
    ['Hari 1 - Kardio & Core', 'Treadmill Interval', 1, '20 menit', 0],
    ['Hari 1 - Kardio & Core', 'Plank', 3, '45 detik', 45],
    ['Hari 2 - Full Body', 'Goblet Squat', 3, '12-15', 60],
  ]);

  console.log('Seed selesai. Semua akun demo memakai password:', DEMO_PASSWORD);
  console.log('  Member : andra.setya@email.com / budi@email.com');
  console.log('  PT     : alex.pt@gymfit.com');
  console.log('  Admin  : admin@gymfit.com');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
