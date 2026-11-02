import { execSync } from 'child_process';
import * as fs from 'fs';
import * as os from 'os';
import * as path from 'path';
import Database from 'better-sqlite3';

const dbFile = path.join(os.tmpdir(), `gymfit-admin-test-${process.pid}.db`);
const uploadDir = fs.mkdtempSync(path.join(os.tmpdir(), 'gymfit-uploads-'));
process.env.DATABASE_URL = `file:${dbFile}`;
process.env.JWT_SECRET = 'test-secret';
process.env.UPLOAD_DIR = uploadDir;

import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { AppModule } from '../src/app.module';

// PNG 1x1
const PNG = Buffer.from(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
  'base64',
);

describe('Website admin (e2e)', () => {
  let app: INestApplication;
  let server: any;
  const auth = (t: string) => ({ Authorization: `Bearer ${t}` });
  const login = async (identifier: string, password = 'password123') =>
    (await request(server).post('/auth/login').send({ identifier, password }).expect(201)).body.accessToken as string;

  const registerGym = (over: Record<string, string> = {}, withImage = true) => {
    let r = request(server)
      .post('/gym-applications')
      .field('ownerName', 'Rina Pemilik')
      .field('birthPlace', 'Surabaya')
      .field('birthDate', '1990-05-17')
      .field('email', over.email ?? 'rina@gymbaru.com')
      .field('password', 'rahasia123')
      .field('gymName', over.gymName ?? 'Iron Temple Surabaya')
      .field('city', 'Surabaya')
      .field('address', 'Jl. Raya Darmo No. 10, Surabaya');
    if (withImage) r = r.attach('images', PNG, { filename: 'fasilitas.png', contentType: 'image/png' });
    return r;
  };

  beforeAll(async () => {
    const db = new Database(dbFile);
    db.exec(fs.readFileSync(path.join(__dirname, 'test-schema.sql'), 'utf8'));
    db.close();
    execSync('npx ts-node prisma/seed.ts', { env: process.env, stdio: 'pipe' });
    const moduleRef = await Test.createTestingModule({ imports: [AppModule] }).compile();
    app = moduleRef.createNestApplication();
    app.useGlobalPipes(new ValidationPipe({ whitelist: true, transform: true }));
    await app.init();
    server = app.getHttpServer();
  });

  afterAll(async () => {
    await app.close();
    for (const f of [dbFile, `${dbFile}-journal`]) if (fs.existsSync(f)) fs.unlinkSync(f);
    fs.rmSync(uploadDir, { recursive: true, force: true });
  });

  it('daftar gym baru: langsung muncul di GET /gyms (yang dibaca aplikasi HP) + foto tersimpan', async () => {
    const res = await registerGym().expect(201);
    expect(res.body.user.role).toBe('ADMIN');
    expect(res.body.user.passwordHash).toBeUndefined();
    expect(res.body.gym.imageUrl).toMatch(/^\/uploads\/.+\.png$/);
    expect(fs.readdirSync(uploadDir)).toHaveLength(1);

    const gyms = (await request(server).get('/gyms').expect(200)).body;
    expect(gyms).toHaveLength(4);
    const baru = gyms.find((g: any) => g.name === 'Iron Temple Surabaya');
    expect(baru.images).toHaveLength(1);
    expect(baru.trainerCount).toBe(0);
  });

  it('pendaftaran ditolak: email/nama ganda (409), data kurang (400), file bukan gambar (400) -- tanpa file sisa', async () => {
    await registerGym().expect(409); // email sama
    await registerGym({ email: 'lain@x.com', gymName: 'Iron Temple Surabaya' }).expect(409);
    const before = fs.readdirSync(uploadDir).length;
    await registerGym({ email: 'a@x.com', gymName: 'Gym Lain' }, true).field('city', 'x').expect(400); // city 'x' < 2 char
    await request(server)
      .post('/gym-applications')
      .field('ownerName', 'Bad').field('birthPlace', 'x1').field('birthDate', '2000-01-01')
      .field('email', 'bad@x.com').field('password', 'abcdef').field('gymName', 'Gym Bad')
      .field('city', 'Kota').field('address', 'Jalan panjang 1')
      .attach('images', Buffer.from('<?php ?>'), { filename: 'x.php', contentType: 'application/x-php' })
      .expect(400);
    expect(fs.readdirSync(uploadDir).length).toBe(before);
  });

  it('login admin per cabang + dashboard', async () => {
    const token = await login('rina@gymbaru.com', 'rahasia123');
    const d = (await request(server).get('/admin/dashboard').set(auth(token)).expect(200)).body;
    expect(d).toMatchObject({ gymName: 'Iron Temple Surabaya', activeMembers: 0, trainers: 0, sessionsThisWeek: 0, revenueTotal: 0 });
    expect(d.checklist).toMatchObject({ hasPlans: false, hasPhotos: true, hasTrainers: false });
  });

  it('hanya ADMIN: member & PT ditolak (403), tanpa token 401', async () => {
    await request(server).get('/admin/dashboard').expect(401);
    const siti = await login('siti@email.com');
    const alex = await login('alex.pt@gymfit.com');
    await request(server).get('/admin/dashboard').set(auth(siti)).expect(403);
    await request(server).get('/admin/trainers').set(auth(alex)).expect(403);
  });

  it('CRUD cabang: info, fasilitas, paket, foto', async () => {
    const t = await login('rina@gymbaru.com', 'rahasia123');
    const upd = await request(server).patch('/admin/gym').set(auth(t)).send({ phone: '08123', openHours: '05.00 - 23.00' }).expect(200);
    expect(upd.body.phone).toBe('08123');

    const fac = (await request(server).post('/admin/gym/facilities').set(auth(t)).send({ label: 'Sauna' }).expect(201)).body;
    await request(server).patch(`/admin/gym/facilities/${fac.id}`).set(auth(t)).send({ label: 'Sauna & Steam' }).expect(200);
    await request(server).delete(`/admin/gym/facilities/${fac.id}`).set(auth(t)).expect(200);

    const plan = (await request(server).post('/admin/gym/plans').set(auth(t)).send({ name: 'Bulanan', price: 250000, durationDays: 30, isPopular: true }).expect(201)).body;
    expect(plan.price).toBe(250000);
    await request(server).post('/admin/gym/plans').set(auth(t)).send({ name: 'X', price: -1, durationDays: 0 }).expect(400);
    await request(server).patch(`/admin/gym/plans/${plan.id}`).set(auth(t)).send({ price: 275000 }).expect(200);

    const withImg = (await request(server).post('/admin/gym/images').set(auth(t)).attach('images', PNG, { filename: 'b.png', contentType: 'image/png' }).expect(201)).body;
    expect(withImg.images).toHaveLength(2);
    const first = withImg.images[0];
    const after = (await request(server).delete(`/admin/gym/images/${first.id}`).set(auth(t)).expect(200)).body;
    expect(after.images).toHaveLength(1);
    expect(after.imageUrl).toBe(after.images[0].url); // sampul pindah ke foto tersisa
    expect(fs.readdirSync(uploadDir)).toHaveLength(1);
  });

  it('CRUD PT: tambah, ubah, nonaktifkan -> hilang dari aplikasi & tak bisa dibooking, hapus', async () => {
    const t = await login('rina@gymbaru.com', 'rahasia123');
    const pt = (await request(server).post('/admin/trainers').set(auth(t))
      .send({ name: 'Dani PT', email: 'dani@gymbaru.com', password: 'dani1234', specialization: 'Strength' }).expect(201)).body;
    expect(pt.isActive).toBe(true);
    await request(server).post('/admin/trainers').set(auth(t)).send({ name: 'Dup', email: 'dani@gymbaru.com', password: 'dani1234', specialization: 'x1' }).expect(409);

    // PT baru bisa login ke aplikasi & tampil di daftar publik
    await login('dani@gymbaru.com', 'dani1234');
    const siti = await login('siti@email.com');
    const gymId = pt.gymId;
    let list = (await request(server).get(`/trainers?gymId=${gymId}`).set(auth(siti))).body;
    expect(list).toHaveLength(1);

    await request(server).patch(`/admin/trainers/${pt.id}`).set(auth(t)).send({ bio: 'Coach strength', experienceYears: 4 }).expect(200);
    const off = (await request(server).patch(`/admin/trainers/${pt.id}`).set(auth(t)).send({ isActive: false }).expect(200)).body;
    expect(off.isActive).toBe(false);

    list = (await request(server).get(`/trainers?gymId=${gymId}`).set(auth(siti))).body;
    expect(list).toHaveLength(0);
    const gyms = (await request(server).get('/gyms')).body;
    expect(gyms.find((g: any) => g.id === gymId).trainerCount).toBe(0);
    const adminList = (await request(server).get('/admin/trainers').set(auth(t)).expect(200)).body;
    expect(adminList).toHaveLength(1); // admin tetap melihatnya

    await request(server).post('/bookings').set(auth(siti))
      .send({ trainerId: pt.id, scheduledAt: new Date(Date.now() + 86400000).toISOString() }).expect(400);

    await request(server).delete(`/admin/trainers/${pt.id}`).set(auth(t)).expect(200);
    expect((await request(server).get('/admin/trainers').set(auth(t))).body).toHaveLength(0);
  });

  it('isolasi cabang: admin cabang lain tidak bisa melihat/mengubah data cabang ini', async () => {
    const t = await login('rina@gymbaru.com', 'rahasia123');
    const pt = (await request(server).post('/admin/trainers').set(auth(t))
      .send({ name: 'Eko PT', email: 'eko@gymbaru.com', password: 'eko12345', specialization: 'Yoga' }).expect(201)).body;
    const plan = (await request(server).get('/admin/gym').set(auth(t))).body.plans[0];

    await registerGym({ email: 'bima@lain.com', gymName: 'Gym Bima Malang' }, false).expect(201);
    const other = await login('bima@lain.com', 'rahasia123');
    await request(server).patch(`/admin/trainers/${pt.id}`).set(auth(other)).send({ isActive: false }).expect(404);
    await request(server).delete(`/admin/trainers/${pt.id}`).set(auth(other)).expect(404);
    await request(server).patch(`/admin/gym/plans/${plan.id}`).set(auth(other)).send({ price: 1 }).expect(404);
    expect((await request(server).get('/admin/trainers').set(auth(other))).body).toHaveLength(0);
    // gym tanpa foto: sampul kosong, tetap valid
    expect((await request(server).get('/admin/gym').set(auth(other))).body.imageUrl).toBe('');
  });

  it('member & membership: daftar manual (akun otomatis), pendapatan, ubah status, hapus', async () => {
    const t = await login('rina@gymbaru.com', 'rahasia123');
    const plan = (await request(server).get('/admin/gym').set(auth(t))).body.plans[0];
    const created = (await request(server).post('/admin/memberships').set(auth(t))
      .send({ name: 'Walk In', email: 'walkin@mail.com', planId: plan.id }).expect(201)).body;
    expect(created.temporaryPassword).toHaveLength(8);
    await login('walkin@mail.com', created.temporaryPassword); // akun bisa dipakai di HP

    const d = (await request(server).get('/admin/dashboard').set(auth(t))).body;
    expect(d).toMatchObject({ activeMembers: 1, revenueTotal: 275000, revenueThisMonth: 275000 });

    const list = (await request(server).get('/admin/memberships').set(auth(t))).body;
    expect(list).toHaveLength(1);
    expect(list[0]).toMatchObject({ status: 'ACTIVE', daysLeft: 30 });
    // paket yang sudah dipakai tak bisa dihapus
    await request(server).delete(`/admin/gym/plans/${plan.id}`).set(auth(t)).expect(409);

    const id = created.membership.id;
    expect((await request(server).patch(`/admin/memberships/${id}`).set(auth(t)).send({ status: 'EXPIRED' }).expect(200)).body.status).toBe('EXPIRED');
    expect((await request(server).get('/admin/dashboard').set(auth(t))).body.activeMembers).toBe(0);
    await request(server).delete(`/admin/memberships/${id}`).set(auth(t)).expect(200);
    expect((await request(server).get('/admin/memberships').set(auth(t))).body).toHaveLength(0);
  });

  it('booking & sesi: admin cabang Sudirman melihat data seed, ubah status, tenant-safe', async () => {
    const t = await login('admin@gymfit.com');
    const list = (await request(server).get('/admin/bookings').set(auth(t)).expect(200)).body;
    expect(list.length).toBeGreaterThan(0);
    expect(list[0]).toHaveProperty('client.name');
    expect(list[0]).toHaveProperty('trainer.user.name');
    const pending = list.find((b: any) => b.status === 'PENDING');
    if (pending) {
      const r = await request(server).patch(`/admin/bookings/${pending.id}`).set(auth(t)).send({ status: 'CANCELLED' }).expect(200);
      expect(r.body.status).toBe('CANCELLED');
      await request(server).patch(`/admin/bookings/${pending.id}`).set(auth(t)).send({ status: 'ACCEPTED' }).expect(400);
    }
    const other = await login('bima@lain.com', 'rahasia123');
    expect((await request(server).get('/admin/bookings').set(auth(other))).body).toHaveLength(0);
    if (list[0]) await request(server).delete(`/admin/bookings/${list[0].id}`).set(auth(other)).expect(404);
    const d = (await request(server).get('/admin/dashboard').set(auth(t))).body;
    expect(d.activeMembers).toBeGreaterThan(0);
    expect(d.trainers).toBeGreaterThan(0);
  });
});
