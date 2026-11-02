import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../database/prisma/prisma.service';
import { CreateWorkoutItemDto, UpdateWorkoutItemDto } from './dto/workout-plan.dto';

const itemInclude = {
  trainer: { select: { id: true, user: { select: { name: true } } } },
} as const;

function startOfToday() {
  const d = new Date();
  d.setHours(0, 0, 0, 0);
  return d;
}

@Injectable()
export class WorkoutPlansService {
  constructor(private readonly prisma: PrismaService) {}

  private async trainerOf(userId: string) {
    const t = await this.prisma.trainerProfile.findUnique({ where: { userId } });
    if (!t) throw new NotFoundException('Profil trainer tidak ditemukan');
    return t;
  }

  /** PT hanya boleh mengelola program klien yang pernah booking dengannya. */
  private async assertClientOf(trainerId: string, clientId: string) {
    const rel = await this.prisma.booking.findFirst({ where: { trainerId, clientId } });
    if (!rel) throw new ForbiddenException('Klien ini belum menjadi klien Anda');
  }

  /** Program latihan MILIK member yang login (id dari token). */
  async forMember(clientId: string) {
    const items = await this.prisma.workoutPlanItem.findMany({
      where: { clientId },
      include: itemInclude,
      orderBy: [{ dayLabel: 'asc' }, { position: 'asc' }],
    });
    const todayLogs = await this.prisma.workoutLog.findMany({
      where: { clientId, createdAt: { gte: startOfToday() }, itemId: { not: null } },
      select: { itemId: true },
    });
    const doneToday = new Set(todayLogs.map((l) => l.itemId));
    return {
      items: items.map((i) => ({ ...i, doneToday: doneToday.has(i.id) })),
    };
  }

  /** Member menandai satu gerakan selesai (masuk ke log progres). */
  async markDone(clientId: string, itemId: string) {
    const item = await this.prisma.workoutPlanItem.findUnique({ where: { id: itemId } });
    if (!item || item.clientId !== clientId) {
      throw new NotFoundException('Gerakan tidak ditemukan');
    }
    const already = await this.prisma.workoutLog.findFirst({
      where: { clientId, itemId, createdAt: { gte: startOfToday() } },
    });
    if (already) return { ok: true, alreadyDone: true };
    await this.prisma.workoutLog.create({
      data: { clientId, itemId, exerciseName: item.exercise },
    });
    return { ok: true, alreadyDone: false };
  }

  /** Batalkan tanda selesai hari ini (salah tekan). */
  async undoDone(clientId: string, itemId: string) {
    await this.prisma.workoutLog.deleteMany({
      where: { clientId, itemId, createdAt: { gte: startOfToday() } },
    });
    return { ok: true };
  }

  async forClient(userId: string, clientId: string) {
    const trainer = await this.trainerOf(userId);
    await this.assertClientOf(trainer.id, clientId);
    const client = await this.prisma.user.findUnique({
      where: { id: clientId },
      select: { id: true, name: true },
    });
    const items = await this.prisma.workoutPlanItem.findMany({
      where: { clientId, trainerId: trainer.id },
      include: itemInclude,
      orderBy: [{ dayLabel: 'asc' }, { position: 'asc' }],
    });
    return { client, items: items.map((i) => ({ ...i, doneToday: false })) };
  }

  async create(userId: string, clientId: string, dto: CreateWorkoutItemDto) {
    const trainer = await this.trainerOf(userId);
    await this.assertClientOf(trainer.id, clientId);
    const last = await this.prisma.workoutPlanItem.findFirst({
      where: { clientId, trainerId: trainer.id, dayLabel: dto.dayLabel },
      orderBy: { position: 'desc' },
    });
    return this.prisma.workoutPlanItem.create({
      data: {
        clientId,
        trainerId: trainer.id,
        dayLabel: dto.dayLabel,
        exercise: dto.exercise,
        sets: dto.sets,
        reps: dto.reps,
        restSec: dto.restSec ?? null,
        note: dto.note ?? '',
        position: (last?.position ?? -1) + 1,
      },
      include: itemInclude,
    });
  }

  async update(userId: string, id: string, dto: UpdateWorkoutItemDto) {
    await this.ownItem(userId, id);
    return this.prisma.workoutPlanItem.update({ where: { id }, data: dto, include: itemInclude });
  }

  async remove(userId: string, id: string) {
    await this.ownItem(userId, id);
    await this.prisma.workoutPlanItem.delete({ where: { id } });
    return { ok: true };
  }

  private async ownItem(userId: string, id: string) {
    const trainer = await this.trainerOf(userId);
    const item = await this.prisma.workoutPlanItem.findUnique({ where: { id } });
    if (!item) throw new NotFoundException('Gerakan tidak ditemukan');
    if (item.trainerId !== trainer.id) {
      throw new ForbiddenException('Gerakan ini dibuat PT lain');
    }
    return item;
  }
}
