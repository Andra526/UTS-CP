import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { DEFAULT_PACKAGE_SESSIONS } from '../../common/utils/session-package';
import { PrismaService } from '../../database/prisma/prisma.service';

export interface PackageSummary {
  trainerId: string;
  trainerName: string;
  total: number; // kuota (default 8)
  used: number; // sesi COMPLETED
  reserved: number; // sesi PENDING/ACCEPTED yang sudah dipesan
  remaining: number; // total - used  -> "Sisa sesi"
  available: number; // total - used - reserved -> masih boleh booking berapa lagi
}

@Injectable()
export class SessionPackagesService {
  constructor(private readonly prisma: PrismaService) {}

  /** Pastikan paket ada (dibuat otomatis 8 sesi saat booking pertama). */
  ensure(clientId: string, trainerId: string) {
    return this.prisma.sessionPackage.upsert({
      where: { clientId_trainerId: { clientId, trainerId } },
      update: {},
      create: { clientId, trainerId, totalSessions: DEFAULT_PACKAGE_SESSIONS },
    });
  }

  /** Ringkasan kuota satu pasangan klien-PT. Tidak membuat data baru. */
  async summarize(clientId: string, trainerId: string): Promise<PackageSummary> {
    const [pkg, trainer, used, reserved] = await Promise.all([
      this.prisma.sessionPackage.findUnique({
        where: { clientId_trainerId: { clientId, trainerId } },
      }),
      this.prisma.trainerProfile.findUnique({
        where: { id: trainerId },
        select: { user: { select: { name: true } } },
      }),
      this.prisma.booking.count({ where: { clientId, trainerId, status: 'COMPLETED' } }),
      this.prisma.booking.count({
        where: { clientId, trainerId, status: { in: ['PENDING', 'ACCEPTED'] } },
      }),
    ]);
    const total = pkg?.totalSessions ?? DEFAULT_PACKAGE_SESSIONS;
    return {
      trainerId,
      trainerName: trainer?.user.name ?? '',
      total,
      used,
      reserved,
      remaining: Math.max(0, total - used),
      available: Math.max(0, total - used - reserved),
    };
  }

  /** Semua paket milik member yang login (satu per PT yang pernah dibooking). */
  async forMember(clientId: string) {
    const [pkgs, bookings] = await Promise.all([
      this.prisma.sessionPackage.findMany({ where: { clientId } }),
      this.prisma.booking.findMany({
        where: { clientId },
        select: { trainerId: true },
        distinct: ['trainerId'],
      }),
    ]);
    const trainerIds = new Set<string>([
      ...pkgs.map((p) => p.trainerId),
      ...bookings.map((b) => b.trainerId),
    ]);
    const items = await Promise.all(
      [...trainerIds].map((tid) => this.summarize(clientId, tid)),
    );
    return { items };
  }

  /** Member melihat kuotanya dengan satu PT (dipakai di layar booking). */
  memberWithTrainer(clientId: string, trainerId: string) {
    return this.summarize(clientId, trainerId);
  }

  private async trainerOf(userId: string) {
    const t = await this.prisma.trainerProfile.findUnique({ where: { userId } });
    if (!t) throw new NotFoundException('Profil trainer tidak ditemukan');
    return t;
  }

  private async assertClientOf(trainerId: string, clientId: string) {
    const rel = await this.prisma.booking.findFirst({ where: { trainerId, clientId } });
    if (!rel) throw new ForbiddenException('Klien ini belum menjadi klien Anda');
  }

  /** PT melihat kuota salah satu kliennya. */
  async forClient(userId: string, clientId: string) {
    const trainer = await this.trainerOf(userId);
    await this.assertClientOf(trainer.id, clientId);
    return this.summarize(clientId, trainer.id);
  }

  /** PT menambah kuota klien (mis. +8 setelah paket habis). */
  async addQuota(userId: string, clientId: string, amount: number) {
    const trainer = await this.trainerOf(userId);
    await this.assertClientOf(trainer.id, clientId);
    await this.ensure(clientId, trainer.id);
    await this.prisma.sessionPackage.update({
      where: { clientId_trainerId: { clientId, trainerId: trainer.id } },
      data: { totalSessions: { increment: amount } },
    });
    return this.summarize(clientId, trainer.id);
  }
}
