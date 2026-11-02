import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../database/prisma/prisma.service';
import { CreateMealDto, UpdateMealDto } from './dto/meal-plan.dto';

const itemInclude = {
  trainer: { select: { id: true, user: { select: { name: true } } } },
} as const;

@Injectable()
export class MealPlansService {
  constructor(private readonly prisma: PrismaService) {}

  private async trainerOf(userId: string) {
    const t = await this.prisma.trainerProfile.findUnique({ where: { userId } });
    if (!t) throw new NotFoundException('Profil trainer tidak ditemukan');
    return t;
  }

  /** PT hanya boleh mengelola pola makan klien yang pernah booking dengannya. */
  private async assertClientOf(trainerId: string, clientId: string) {
    const rel = await this.prisma.booking.findFirst({ where: { trainerId, clientId } });
    if (!rel) throw new ForbiddenException('Klien ini belum menjadi klien Anda');
  }

  private summarize<T extends { calories: number; protein: number }>(items: T[]) {
    return {
      items,
      totals: {
        calories: items.reduce((a, i) => a + i.calories, 0),
        protein: items.reduce((a, i) => a + i.protein, 0),
      },
    };
  }

  /** Pola makan MILIK member yang login (id dari token, bukan dari URL). */
  async forMember(clientId: string) {
    const [items, goals] = await Promise.all([
      this.prisma.mealPlanItem.findMany({
        where: { clientId },
        include: itemInclude,
        orderBy: { time: 'asc' },
      }),
      this.prisma.clientGoal.findMany({ where: { clientId } }),
    ]);
    const goal = goals[0] ?? null;
    return {
      ...this.summarize(items),
      target: goal
        ? { description: goal.description, calories: goal.targetCalories, protein: goal.targetProtein }
        : null,
    };
  }

  /** Pola makan satu klien, dibuat oleh PT yang login. */
  async forClient(userId: string, clientId: string) {
    const trainer = await this.trainerOf(userId);
    await this.assertClientOf(trainer.id, clientId);
    const client = await this.prisma.user.findUnique({
      where: { id: clientId },
      select: { id: true, name: true },
    });
    const items = await this.prisma.mealPlanItem.findMany({
      where: { clientId, trainerId: trainer.id },
      include: itemInclude,
      orderBy: { time: 'asc' },
    });
    return { client, ...this.summarize(items) };
  }

  async create(userId: string, clientId: string, dto: CreateMealDto) {
    const trainer = await this.trainerOf(userId);
    await this.assertClientOf(trainer.id, clientId);
    return this.prisma.mealPlanItem.create({
      data: { clientId, trainerId: trainer.id, ...dto },
      include: itemInclude,
    });
  }

  async update(userId: string, id: string, dto: UpdateMealDto) {
    await this.ownItem(userId, id);
    return this.prisma.mealPlanItem.update({ where: { id }, data: dto, include: itemInclude });
  }

  async remove(userId: string, id: string) {
    await this.ownItem(userId, id);
    await this.prisma.mealPlanItem.delete({ where: { id } });
    return { ok: true };
  }

  private async ownItem(userId: string, id: string) {
    const trainer = await this.trainerOf(userId);
    const item = await this.prisma.mealPlanItem.findUnique({ where: { id } });
    if (!item) throw new NotFoundException('Menu tidak ditemukan');
    if (item.trainerId !== trainer.id) {
      throw new ForbiddenException('Menu ini dibuat PT lain');
    }
    return item;
  }
}
