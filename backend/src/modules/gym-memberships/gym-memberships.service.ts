import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../database/prisma/prisma.service';

const DAY_MS = 24 * 60 * 60 * 1000;

@Injectable()
export class GymMembershipsService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Pembelian paket. Pembayaran masih SIMULASI (langsung berhasil).
   * Ganti dengan payment gateway (Midtrans/Xendit) di tahap berikutnya.
   */
  async purchase(userId: string, planId: string) {
    const plan = await this.prisma.gymPlan.findUnique({ where: { id: planId } });
    if (!plan) throw new NotFoundException('Paket tidak ditemukan');

    // Jika masih punya membership aktif di gym yang sama, perpanjang dari tanggal berakhir.
    const current = await this.findActiveForGym(userId, plan.gymId);
    const start = current ? current.endDate : new Date();
    const end = new Date(start.getTime() + plan.durationDays * DAY_MS);

    const membership = await this.prisma.gymMembership.create({
      data: {
        userId,
        gymId: plan.gymId,
        planId: plan.id,
        price: plan.price,
        startDate: start,
        endDate: end,
        status: 'ACTIVE',
      },
      include: { gym: true, plan: true },
    });
    return this.withRemaining(membership);
  }

  async findMine(userId: string) {
    await this.expireOld(userId);
    const list = await this.prisma.gymMembership.findMany({
      where: { userId },
      include: { gym: true, plan: true },
      orderBy: { startDate: 'desc' },
    });
    return list.map((m) => this.withRemaining(m));
  }

  /** Membership aktif dengan masa berlaku terpanjang, atau null. */
  async findActive(userId: string) {
    await this.expireOld(userId);
    const active = await this.prisma.gymMembership.findFirst({
      where: { userId, status: 'ACTIVE', endDate: { gt: new Date() } },
      include: { gym: true, plan: true },
      orderBy: { endDate: 'desc' },
    });
    return active ? this.withRemaining(active) : null;
  }

  async hasActiveMembership(userId: string, gymId: string) {
    return (await this.findActiveForGym(userId, gymId)) !== null;
  }

  private findActiveForGym(userId: string, gymId: string) {
    return this.prisma.gymMembership.findFirst({
      where: { userId, gymId, status: 'ACTIVE', endDate: { gt: new Date() } },
      orderBy: { endDate: 'desc' },
    });
  }

  private async expireOld(userId: string) {
    await this.prisma.gymMembership.updateMany({
      where: { userId, status: 'ACTIVE', endDate: { lte: new Date() } },
      data: { status: 'EXPIRED' },
    });
  }

  private withRemaining<T extends { endDate: Date }>(m: T) {
    const remainingSeconds = Math.max(
      0,
      Math.floor((m.endDate.getTime() - Date.now()) / 1000),
    );
    return { ...m, remainingSeconds };
  }
}
