import { execSync } from 'child_process';
import * as fs from 'fs';
import * as os from 'os';
import * as path from 'path';
import Database from 'better-sqlite3';

const dbFile = path.join(os.tmpdir(), `gymfit-meals-test-${process.pid}.db`);
process.env.DATABASE_URL = `file:${dbFile}`;
process.env.JWT_SECRET = 'test-secret';

import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { AppModule } from '../src/app.module';

describe('Pola makan & tujuan program (e2e)', () => {
  let app: INestApplication;
  let server: any;
  const auth = (t: string) => ({ Authorization: `Bearer ${t}` });
  const login = async (identifier: string) =>
    (await request(server).post('/auth/login').send({ identifier, password: 'password123' }).expect(201)).body.accessToken as string;

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
  });

  it('member hanya melihat pola makan MILIKNYA (Andra != Budi)', async () => {
    const andra = await login('andra.setya@email.com');
    const budi = await login('budi@email.com');
    const siti = await login('siti@email.com');
    const a = (await request(server).get('/meal-plans/me').set(auth(andra)).expect(200)).body;
    const b = (await request(server).get('/meal-plans/me').set(auth(budi)).expect(200)).body;
    const s = (await request(server).get('/meal-plans/me').set(auth(siti)).expect(200)).body;
    expect(a.items).toHaveLength(4);
    expect(a.totals).toEqual({ calories: 2210, protein: 166 });
    expect(a.target).toMatchObject({ calories: 3000, protein: 190 });
    expect(b.items).toHaveLength(3);
    expect(b.items.map((i: any) => i.id)).not.toEqual(expect.arrayContaining([a.items[0].id]));
    expect(s.items).toHaveLength(0); // belum punya pola makan
    expect(s.target).toBeNull();
  });

  it('member tidak bisa membuka endpoint PT / mengubah menu', async () => {
    const andra = await login('andra.setya@email.com');
    const items = (await request(server).get('/meal-plans/me').set(auth(andra))).body.items;
    await request(server).get('/meal-plans/client/xxx').set(auth(andra)).expect(403);
    await request(server).patch(`/meal-plans/${items[0].id}`).set(auth(andra)).send({ calories: 1 }).expect(403);
    await request(server).delete(`/meal-plans/${items[0].id}`).set(auth(andra)).expect(403);
    await request(server).get('/meal-plans/me').expect(401);
  });

  it('PT: CRUD pola makan satu klien, perubahan langsung terlihat di akun member', async () => {
    const alex = await login('alex.pt@gymfit.com');
    const andra = await login('andra.setya@email.com');
    const andraId = (await request(server).get('/auth/me').set(auth(andra))).body.id;

    const view = (await request(server).get(`/meal-plans/client/${andraId}`).set(auth(alex)).expect(200)).body;
    expect(view.client.name).toContain('Andra');
    expect(view.items).toHaveLength(4);

    // tambah
    const created = (await request(server).post(`/meal-plans/client/${andraId}`).set(auth(alex))
      .send({ time: '22:00', category: 'Snack Malam', description: '30g casein + 1 sdm selai kacang', calories: 250, protein: 28 }).expect(201)).body;
    let mine = (await request(server).get('/meal-plans/me').set(auth(andra))).body;
    expect(mine.items).toHaveLength(5);
    expect(mine.items[4].category).toBe('Snack Malam'); // urut jam

    // ubah
    await request(server).patch(`/meal-plans/${created.id}`).set(auth(alex)).send({ calories: 300, description: 'Casein + pisang' }).expect(200);
    mine = (await request(server).get('/meal-plans/me').set(auth(andra))).body;
    expect(mine.items.find((i: any) => i.id === created.id)).toMatchObject({ calories: 300, description: 'Casein + pisang' });
    expect(mine.totals.calories).toBe(2510);

    // validasi
    await request(server).post(`/meal-plans/client/${andraId}`).set(auth(alex)).send({ time: '25:99', category: 'X1', description: 'abc', calories: 1, protein: 1 }).expect(400);
    await request(server).patch(`/meal-plans/${created.id}`).set(auth(alex)).send({ calories: -5 }).expect(400);

    // hapus
    await request(server).delete(`/meal-plans/${created.id}`).set(auth(alex)).expect(200);
    mine = (await request(server).get('/meal-plans/me').set(auth(andra))).body;
    expect(mine.items).toHaveLength(4);
  });

  it('PT tidak bisa mengelola klien lain / menu PT lain', async () => {
    const alex = await login('alex.pt@gymfit.com');
    const sarah = await login('sarah.pt@gymfit.com');
    const andra = await login('andra.setya@email.com');
    const andraId = (await request(server).get('/auth/me').set(auth(andra))).body.id;
    const item = (await request(server).get('/meal-plans/me').set(auth(andra))).body.items[0];
    // Sarah belum punya hubungan dengan Andra
    await request(server).get(`/meal-plans/client/${andraId}`).set(auth(sarah)).expect(403);
    await request(server).post(`/meal-plans/client/${andraId}`).set(auth(sarah))
      .send({ time: '08:00', category: 'Sarapan', description: 'abc def', calories: 100, protein: 5 }).expect(403);
    await request(server).patch(`/meal-plans/${item.id}`).set(auth(sarah)).send({ calories: 1 }).expect(403);
    await request(server).delete(`/meal-plans/${item.id}`).set(auth(sarah)).expect(403);
    await request(server).patch('/meal-plans/tidak-ada').set(auth(alex)).send({ calories: 100 }).expect(404);
  });

  it('booking membawa paket tujuan; nilai tak dikenal ditolak; tampil di daftar klien PT', async () => {
    const siti = await login('siti@email.com');
    const trainers = (await request(server).get('/trainers').set(auth(siti))).body;
    const alexId = trainers.find((t: any) => t.user.name.includes('Alex')).id;
    const when = new Date(Date.now() + 10 * 86400000).toISOString();

    await request(server).post('/bookings').set(auth(siti)).send({ trainerId: alexId, scheduledAt: when, goalType: 'TERBANG' }).expect(400);
    const ok = (await request(server).post('/bookings').set(auth(siti)).send({ trainerId: alexId, scheduledAt: when, goalType: 'WEIGHT_LOSS' }).expect(201)).body;
    expect(ok.goalType).toBe('WEIGHT_LOSS');
    const def = (await request(server).post('/bookings').set(auth(siti))
      .send({ trainerId: alexId, scheduledAt: new Date(Date.now() + 11 * 86400000).toISOString() }).expect(201)).body;
    expect(def.goalType).toBe('GENERAL');

    const alex = await login('alex.pt@gymfit.com');
    const clients = (await request(server).get('/clients').set(auth(alex)).expect(200)).body;
    const andra = clients.find((c: any) => c.name.includes('Andra'));
    expect(andra.goalType).toBe('MUSCLE_GAIN');
    const budi = clients.find((c: any) => c.name.includes('Budi'));
    expect(budi.goalType).toBe('WEIGHT_LOSS');
  });
});
