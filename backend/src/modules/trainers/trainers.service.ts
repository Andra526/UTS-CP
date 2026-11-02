import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../database/prisma/prisma.service';
import { UpdateTrainerDto } from './dto/update-trainer.dto';

const trainerInclude = {
  user: { select: { id: true, name: true, email: true, photoUrl: true } },
  gym: { select: { id: true, name: true, city: true } },
} as const;

@Injectable()
export class TrainersService {
  constructor(private readonly prisma: PrismaService) {}

  findAll(gymId?: string, search?: string) {
    const q = search?.trim();
    return this.prisma.trainerProfile.findMany({
      where: {
        isActive: true,
        ...(gymId ? { gymId } : {}),
        ...(q
          ? {
              OR: [
                { user: { name: { contains: q } } },
                { specialization: { contains: q } },
              ],
            }
          : {}),
      },
      include: trainerInclude,
      orderBy: { rating: 'desc' },
    });
  }

  async findOne(id: string) {
    const trainer = await this.prisma.trainerProfile.findUnique({
      where: { id },
      include: trainerInclude,
    });
    if (!trainer) throw new NotFoundException('Trainer tidak ditemukan');
    return trainer;
  }

  async findByUserId(userId: string) {
    const trainer = await this.prisma.trainerProfile.findUnique({
      where: { userId },
      include: trainerInclude,
    });
    if (!trainer) throw new NotFoundException('Profil trainer tidak ditemukan');
    return trainer;
  }

  async updateMe(userId: string, dto: UpdateTrainerDto) {
    const me = await this.findByUserId(userId);
    await this.prisma.trainerProfile.update({ where: { id: me.id }, data: dto });
    return this.findOne(me.id);
  }

  /** Ringkasan untuk dashboard PT. */
  async dashboard(userId: string) {
    const me = await this.findByUserId(userId);
    const now = new Date();
    const startOfDay = new Date(now);
    startOfDay.setHours(0, 0, 0, 0);
    const endOfDay = new Date(startOfDay.getTime() + 24 * 60 * 60 * 1000);

    const [activeClients, pendingRequests, todaySessions, nextSession] =
      await Promise.all([
        this.prisma.booking
          .findMany({
            where: {
              trainerId: me.id,
              status: { in: ['ACCEPTED', 'COMPLETED'] },
            },
            select: { clientId: true },
            distinct: ['clientId'],
          })
          .then((rows) => rows.length),
        this.prisma.booking.count({
          where: { trainerId: me.id, status: 'PENDING' },
        }),
        this.prisma.booking.count({
          where: {
            trainerId: me.id,
            status: 'ACCEPTED',
            scheduledAt: { gte: startOfDay, lt: endOfDay },
          },
        }),
        this.prisma.booking.findFirst({
          where: {
            trainerId: me.id,
            status: 'ACCEPTED',
            scheduledAt: { gte: now },
          },
          orderBy: { scheduledAt: 'asc' },
          include: { client: { select: { id: true, name: true, photoUrl: true } } },
        }),
      ]);

    return {
      trainer: me,
      activeClients,
      pendingRequests,
      todaySessions,
      rating: me.rating,
      nextSession,
    };
  }
}
