import { execSync } from 'child_process';
import * as fs from 'fs';
import * as os from 'os';
import * as path from 'path';
import Database from 'better-sqlite3';

// Database khusus tes (file sementara) -- harus diset sebelum app diimpor.
const dbFile = path.join(os.tmpdir(), `gymfit-test-${process.pid}.db`);
process.env.DATABASE_URL = `file:${dbFile}`;
process.env.JWT_SECRET = 'test-secret';

import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { AppModule } from '../src/app.module';

const PASSWORD = 'password123';

describe('GymFit API (e2e)', () => {
  let app: INestApplication;
  let http: ReturnType<typeof request>;

  const login = async (identifier: string) => {
    const res = await request(app.getHttpServer())
      .post('/auth/login')
      .send({ identifier, password: PASSWORD })
      .expect(201);
    return res.body.accessToken as string;
  };
  const auth = (token: string) => ({ Authorization: `Bearer ${token}` });

  beforeAll(async () => {
    // Buat tabel dari skema, lalu isi data awal memakai seed asli.
    const db = new Database(dbFile);
    db.exec(fs.readFileSync(path.join(__dirname, 'test-schema.sql'), 'utf8'));
    db.close();
    execSync('npx ts-node prisma/seed.ts', {
      env: process.env,
      stdio: 'pipe',
    });

    const moduleRef = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();
    app = moduleRef.createNestApplication();
    app.useGlobalPipes(new ValidationPipe({ whitelist: true, transform: true }));
    await app.init();
    http = request(app.getHttpServer()) as any;
  });

  afterAll(async () => {
    await app.close();
    for (const f of [dbFile, `${dbFile}-journal`]) {
      if (fs.existsSync(f)) fs.unlinkSync(f);
    }
  });

  it('GET /health -> ok', async () => {
    const res = await request(app.getHttpServer()).get('/health').expect(200);
    expect(res.body).toMatchObject({ status: 'ok', database: 'up' });
  });

  it('GET /gyms publik: 3 cabang + jumlah PT', async () => {
    const res = await request(app.getHttpServer()).get('/gyms').expect(200);
    expect(res.body).toHaveLength(3);
    const sudirman = res.body.find((g: any) => g.name.includes('Sudirman'));
    expect(sudirman.trainerCount).toBe(2);
    expect(sudirman.plans.map((p: any) => p.name)).toEqual(
      expect.arrayContaining(['Harian', 'Bulanan', 'Tahunan']),
    );
    const search = await request(app.getHttpServer())
      .get('/gyms?search=bandung')
      .expect(200);
    expect(search.body).toHaveLength(1);
  });

  it('endpoint terlindungi: tanpa token 401, token salah 401', async () => {
    await request(app.getHttpServer()).get('/trainers').expect(401);
    await request(app.getHttpServer())
      .get('/trainers')
      .set(auth('bukan-token'))
      .expect(401);
  });

  describe('auth', () => {
    it('login salah -> 401, login benar via email dan role tepat', async () => {
      await request(app.getHttpServer())
        .post('/auth/login')
        .send({ identifier: 'alex.pt@gymfit.com', password: 'salah' })
        .expect(401);
      const res = await request(app.getHttpServer())
        .post('/auth/login')
        .send({ identifier: 'alex.pt@gymfit.com', password: PASSWORD })
        .expect(201);
      expect(res.body.user.role).toBe('TRAINER');
      expect(res.body.user.passwordHash).toBeUndefined();
    });

    it('register: validasi, duplikat, ADMIN ditolak, trainer wajib gym', async () => {
      const server = app.getHttpServer();
      await request(server)
        .post('/auth/register')
        .send({ name: 'A', email: 'bukan-email', password: '123' })
        .expect(400);
      await request(server)
        .post('/auth/register')
        .send({ name: 'Hacker', email: 'h@x.com', password: 'secret1', role: 'ADMIN' })
        .expect(400);
      await request(server)
        .post('/auth/register')
        .send({ name: 'PT Baru', email: 'ptbaru@x.com', password: 'secret1', role: 'TRAINER' })
        .expect(400);
      await request(server)
        .post('/auth/register')
        .send({ name: 'Budi Dua', email: 'budi@email.com', password: 'secret1' })
        .expect(409);
    });
  });

  describe('RBAC & tenant', () => {
    it('member tidak boleh buka dashboard PT', async () => {
      const token = await login('budi@email.com');
      await request(app.getHttpServer())
        .get('/trainers/me/dashboard')
        .set(auth(token))
        .expect(403);
    });

    it('admin hanya boleh ubah cabangnya sendiri', async () => {
      const token = await login('admin@gymfit.com');
      const gyms = (await request(app.getHttpServer()).get('/gyms')).body;
      const own = gyms.find((g: any) => g.name.includes('Sudirman'));
      const other = gyms.find((g: any) => g.name.includes('Bandung'));
      const ok = await request(app.getHttpServer())
        .patch(`/gyms/${own.id}`)
        .set(auth(token))
        .send({ openHours: '04:00 - 23:00 WIB' })
        .expect(200);
      expect(ok.body.openHours).toBe('04:00 - 23:00 WIB');
      await request(app.getHttpServer())
        .patch(`/gyms/${other.id}`)
        .set(auth(token))
        .send({ openHours: 'x' })
        .expect(403);
    });
  });

  describe('PT: dashboard, klien, jadwal', () => {
    let alex: string;
    beforeAll(async () => {
      alex = await login('alex.pt@gymfit.com');
    });

    it('dashboard: 3 klien aktif, 1 request, sesi berikutnya', async () => {
      const res = await request(app.getHttpServer())
        .get('/trainers/me/dashboard')
        .set(auth(alex))
        .expect(200);
      expect(res.body.activeClients).toBe(3);
      expect(res.body.pendingRequests).toBe(1);
      expect(res.body.nextSession.client.name).toBe('Budi Santoso');
    });

    it('daftar klien berisi progres & target', async () => {
      const res = await request(app.getHttpServer())
        .get('/clients')
        .set(auth(alex))
        .expect(200);
      const budi = res.body.find((c: any) => c.name === 'Budi Santoso');
      expect(budi.completedSessions).toBe(1);
      expect(budi.goal.targetCalories).toBe(2800);
      expect(res.body).toHaveLength(4);
    });

    it('jadwal: tambah, validasi, hapus', async () => {
      const server = app.getHttpServer();
      const list = await request(server).get('/trainer-schedules/me').set(auth(alex)).expect(200);
      expect(list.body).toHaveLength(4);
      expect(list.body[0].day).toBe('Senin');

      await request(server)
        .post('/trainer-schedules')
        .set(auth(alex))
        .send({ day: 'Kamis', startTime: '12:00', endTime: '10:00' })
        .expect(400);
      await request(server)
        .post('/trainer-schedules')
        .set(auth(alex))
        .send({ day: 'Hari Libur', startTime: '10:00', endTime: '12:00' })
        .expect(400);
      const created = await request(server)
        .post('/trainer-schedules')
        .set(auth(alex))
        .send({ day: 'Kamis', startTime: '10:00', endTime: '12:00' })
        .expect(201);
      await request(server)
        .delete(`/trainer-schedules/${created.body.id}`)
        .set(auth(alex))
        .expect(200);
    });

    it('target klien: PT boleh untuk kliennya, ditolak untuk orang asing', async () => {
      const server = app.getHttpServer();
      const budiToken = await login('budi@email.com');
      const budiId = (await request(server).get('/users/me').set(auth(budiToken))).body.id;
      // Orang asing: member baru yang belum pernah booking ke Alex.
      const asing = await request(server)
        .post('/auth/register')
        .send({ name: 'Orang Asing', email: 'asing@email.com', password: 'password123' })
        .expect(201);
      const andraId = asing.body.user.id;

      const upd = await request(server)
        .put(`/client-goals/${budiId}`)
        .set(auth(alex))
        .send({ description: 'Turun 5 kg', targetCalories: 2500, targetProtein: 170 })
        .expect(200);
      expect(upd.body.targetCalories).toBe(2500);
      await request(server)
        .put(`/client-goals/${budiId}`)
        .set(auth(alex))
        .send({ description: 'x', targetCalories: 99999 })
        .expect(400);
      await request(server)
        .put(`/client-goals/${andraId}`)
        .set(auth(alex))
        .send({ description: 'Bukan klien saya' })
        .expect(403);
      // Budi bisa lihat targetnya sendiri, tapi tidak punya Andra.
      const mine = await request(server).get(`/client-goals/${budiId}`).set(auth(budiToken)).expect(200);
      expect(mine.body[0].targetCalories).toBe(2500);
      await request(server).get(`/client-goals/${andraId}`).set(auth(budiToken)).expect(403);
    });
  });

  describe('alur lengkap: membership -> booking -> terima -> laporan sesi', () => {
    it('berjalan dari awal sampai akhir', async () => {
      const server = app.getHttpServer();

      // 1. Daftar member baru
      const reg = await request(server)
        .post('/auth/register')
        .send({ name: 'Member Baru', email: 'baru@email.com', password: PASSWORD })
        .expect(201);
      const member = reg.body.accessToken as string;
      expect(reg.body.user.role).toBe('MEMBER');

      const gyms = (await request(server).get('/gyms')).body;
      const sudirman = gyms.find((g: any) => g.name.includes('Sudirman'));
      const monthly = sudirman.plans.find((p: any) => p.name === 'Bulanan');
      const trainers = (
        await request(server).get(`/trainers?gymId=${sudirman.id}`).set(auth(member)).expect(200)
      ).body;
      expect(trainers).toHaveLength(2);
      const alexProfile = trainers.find((t: any) => t.user.name.startsWith('Alex'));

      const slot = new Date(Date.now() + 5 * 24 * 3600 * 1000);
      slot.setHours(9, 0, 0, 0);

      // 2. Tanpa membership -> ditolak
      await request(server)
        .post('/bookings')
        .set(auth(member))
        .send({ trainerId: alexProfile.id, scheduledAt: slot.toISOString() })
        .expect(403);

      // 3. Beli membership
      const active0 = await request(server).get('/memberships/me/active').set(auth(member)).expect(200);
      expect(active0.body.active).toBeNull();
      const bought = await request(server)
        .post('/memberships')
        .set(auth(member))
        .send({ planId: monthly.id })
        .expect(201);
      expect(bought.body.price).toBe(250000);
      expect(bought.body.remainingSeconds).toBeGreaterThan(29 * 86400);
      const active1 = await request(server).get('/memberships/me/active').set(auth(member)).expect(200);
      expect(active1.body.active.gym.id).toBe(sudirman.id);

      // 4. Booking di masa lalu ditolak, di masa depan diterima (PENDING)
      await request(server)
        .post('/bookings')
        .set(auth(member))
        .send({ trainerId: alexProfile.id, scheduledAt: '2020-01-01T10:00:00.000Z' })
        .expect(400);
      const booking = await request(server)
        .post('/bookings')
        .set(auth(member))
        .send({ trainerId: alexProfile.id, scheduledAt: slot.toISOString(), note: 'Mau mulai' })
        .expect(201);
      expect(booking.body.status).toBe('PENDING');

      // 5. PT menerima
      const alex = await login('alex.pt@gymfit.com');
      const pending = await request(server)
        .get('/bookings/trainer?status=PENDING')
        .set(auth(alex))
        .expect(200);
      expect(pending.body.map((b: any) => b.id)).toContain(booking.body.id);
      const accepted = await request(server)
        .patch(`/bookings/${booking.body.id}/status`)
        .set(auth(alex))
        .send({ status: 'ACCEPTED' })
        .expect(200);
      expect(accepted.body.status).toBe('ACCEPTED');
      // dijawab dua kali -> konflik
      await request(server)
        .patch(`/bookings/${booking.body.id}/status`)
        .set(auth(alex))
        .send({ status: 'REJECTED' })
        .expect(409);

      // 6. Member lain tidak bisa ambil slot yang sama (overlap)
      const budi = await login('budi@email.com');
      await request(server)
        .post('/bookings')
        .set(auth(budi))
        .send({ trainerId: alexProfile.id, scheduledAt: slot.toISOString() })
        .expect(409);

      // 7. Member tidak boleh membalas booking sebagai PT
      await request(server)
        .patch(`/bookings/${booking.body.id}/status`)
        .set(auth(member))
        .send({ status: 'ACCEPTED' })
        .expect(403);

      // 8. Laporan sesi -> booking COMPLETED
      await request(server)
        .post('/training-sessions')
        .set(auth(alex))
        .send({ bookingId: booking.body.id, attendance: 'HADIR', intensity: 11 })
        .expect(400);
      const report = await request(server)
        .post('/training-sessions')
        .set(auth(alex))
        .send({ bookingId: booking.body.id, attendance: 'HADIR', intensity: 7, notes: 'Sesi pertama lancar' })
        .expect(201);
      expect(report.body.intensity).toBe(7);
      await request(server)
        .post('/training-sessions')
        .set(auth(alex))
        .send({ bookingId: booking.body.id, attendance: 'HADIR', intensity: 7 })
        .expect(409);

      const mine = await request(server).get('/bookings/me').set(auth(member)).expect(200);
      expect(mine.body[0].status).toBe('COMPLETED');
      const history = await request(server).get('/training-sessions/me').set(auth(member)).expect(200);
      expect(history.body).toHaveLength(1);
      expect(history.body[0].booking.trainer.user.name).toContain('Alex');
    });

    it('member bisa membatalkan booking miliknya, bukan milik orang lain', async () => {
      const server = app.getHttpServer();
      const siti = await login('siti@email.com');
      const budi = await login('budi@email.com');
      const sitiBookings = (await request(server).get('/bookings/me').set(auth(siti))).body;
      const pending = sitiBookings.find((b: any) => b.status === 'PENDING');
      await request(server).patch(`/bookings/${pending.id}/cancel`).set(auth(budi)).expect(403);
      const res = await request(server).patch(`/bookings/${pending.id}/cancel`).set(auth(siti)).expect(200);
      expect(res.body.status).toBe('CANCELLED');
    });
  });
});
