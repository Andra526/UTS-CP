import {
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../database/prisma/prisma.service';
import { CreateTrainingSessionDto } from './dto/create-session.dto';

const sessionInclude = {
  booking: {
    include: {
      client: { select: { id: true, name: true } },
      trainer: { select: { id: true, user: { select: { name: true } } } },
    },
  },
} as const;

@Injectable()
export class TrainingSessionsService {
  constructor(private readonly prisma: PrismaService) {}

  /** Laporan sesi: wajib diisi agar booking ditandai COMPLETED (FR-PT13). */
  async create(userId: string, dto: CreateTrainingSessionDto) {
    const trainer = await this.prisma.trainerProfile.findUnique({
      where: { userId },
    });
    if (!trainer) throw new NotFoundException('Profil trainer tidak ditemukan');

    const booking = await this.prisma.booking.findUnique({
      where: { id: dto.bookingId },
      include: { session: true },
    });
    if (!booking) throw new NotFoundException('Booking tidak ditemukan');
    if (booking.trainerId !== trainer.id) {
      throw new ForbiddenException('Ini bukan sesi Anda');
    }
    if (booking.status !== 'ACCEPTED' || booking.session) {
      throw new ConflictException(
        'Laporan hanya bisa dibuat untuk sesi ACCEPTED yang belum dilaporkan',
      );
    }

    const [session] = await this.prisma.$transaction([
      this.prisma.trainingSession.create({
        data: {
          bookingId: booking.id,
          attendance: dto.attendance,
          intensity: dto.intensity,
          notes: dto.notes ?? '',
        },
        include: sessionInclude,
      }),
      this.prisma.booking.update({
        where: { id: booking.id },
        data: { status: 'COMPLETED' },
      }),
    ]);
    return session;
  }

  findForClient(clientId: string) {
    return this.prisma.trainingSession.findMany({
      where: { booking: { clientId } },
      include: sessionInclude,
      orderBy: { completedAt: 'desc' },
    });
  }

  async findForTrainer(userId: string) {
    const trainer = await this.prisma.trainerProfile.findUnique({
      where: { userId },
    });
    if (!trainer) throw new NotFoundException('Profil trainer tidak ditemukan');
    return this.prisma.trainingSession.findMany({
      where: { booking: { trainerId: trainer.id } },
      include: sessionInclude,
      orderBy: { completedAt: 'desc' },
    });
  }
}
