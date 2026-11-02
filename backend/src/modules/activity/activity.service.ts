import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../database/prisma/prisma.service';

export type ActivityType = 'MEMBERSHIP' | 'BOOKING' | 'SESSION' | 'WORKOUT';

export interface ActivityItem {
  id: string;
  type: ActivityType;
  title: string;
  subtitle: string;
  at: Date;
}

const DAY_MS = 24 * 60 * 60 * 1000;

const BOOKING_TITLE: Record<string, string> = {
  PENDING: 'Request sesi dikirim',
  ACCEPTED: 'Sesi disetujui PT',
  REJECTED: 'Sesi ditolak PT',
  CANCELLED: 'Sesi dibatalkan',
};

@Injectable()
export class ActivityService {
  constructor(private readonly prisma: PrismaService) {}

  /** Log aktivitas MILIK member yang login, gabungan dari beberapa sumber. */
  async forMember(clientId: string, limit = 50) {
    const weekAgo = new Date(Date.now() - 7 * DAY_MS);

    const [memberships, bookings, sessions, logs, workoutsThisWeek, totalWorkouts] =
      await Promise.all([
        this.prisma.gymMembership.findMany({
          where: { userId: clientId },
          include: { gym: true, plan: true },
          orderBy: { createdAt: 'desc' },
          take: limit,
        }),
        this.prisma.booking.findMany({
          where: { clientId, status: { in: ['PENDING', 'ACCEPTED', 'REJECTED', 'CANCELLED'] } },
          include: { trainer: { select: { user: { select: { name: true } } } } },
          orderBy: { updatedAt: 'desc' },
          take: limit,
        }),
        this.prisma.trainingSession.findMany({
          where: { booking: { clientId } },
          include: {
            booking: { include: { trainer: { select: { user: { select: { name: true } } } } } },
          },
          orderBy: { completedAt: 'desc' },
          take: limit,
        }),
        this.prisma.workoutLog.findMany({
          where: { clientId },
          orderBy: { createdAt: 'desc' },
          take: limit,
        }),
        this.prisma.workoutLog.count({ where: { clientId, createdAt: { gte: weekAgo } } }),
        this.prisma.workoutLog.count({ where: { clientId } }),
      ]);

    const items: ActivityItem[] = [
      ...memberships.map((m) => ({
        id: `m-${m.id}`,
        type: 'MEMBERSHIP' as const,
        title: `Membership ${m.plan.name} dibeli`,
        subtitle: m.gym.name,
        at: m.createdAt,
      })),
      ...bookings.map((b) => ({
        id: `b-${b.id}`,
        type: 'BOOKING' as const,
        title: BOOKING_TITLE[b.status] ?? 'Booking diperbarui',
        subtitle: `PT ${b.trainer.user.name}`,
        at: b.status === 'PENDING' ? b.createdAt : b.updatedAt,
      })),
      ...sessions.map((s) => ({
        id: `s-${s.id}`,
        type: 'SESSION' as const,
        title: 'Sesi latihan selesai',
        subtitle: `Bersama ${s.booking.trainer.user.name} • intensitas ${s.intensity}/10`,
        at: s.completedAt,
      })),
      ...logs.map((l) => ({
        id: `w-${l.id}`,
        type: 'WORKOUT' as const,
        title: 'Menyelesaikan gerakan',
        subtitle: l.exerciseName,
        at: l.createdAt,
      })),
    ]
      .sort((a, b) => b.at.getTime() - a.at.getTime())
      .slice(0, limit);

    return {
      stats: {
        sessionsCompleted: sessions.length,
        workoutsThisWeek,
        totalWorkouts,
      },
      items,
    };
  }
}
