import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { AuthUser } from '../../common/decorators/current-user.decorator';
import { PrismaService } from '../../database/prisma/prisma.service';
import { UpsertGoalDto } from './dto/upsert-goal.dto';

@Injectable()
export class ClientGoalsService {
  constructor(private readonly prisma: PrismaService) {}

  /** Klien melihat semua targetnya; PT hanya melihat target buatannya. */
  async find(user: AuthUser, clientId: string) {
    if (user.role === 'MEMBER') {
      if (user.id !== clientId) {
        throw new ForbiddenException('Anda hanya boleh melihat target Anda sendiri');
      }
      return this.prisma.clientGoal.findMany({ where: { clientId } });
    }
    const trainer = await this.trainerOf(user.id);
    return this.prisma.clientGoal.findMany({
      where: { clientId, trainerId: trainer.id },
    });
  }

  /** PT menetapkan target program + target kalori/protein klien (FR-PT10/11). */
  async upsert(userId: string, clientId: string, dto: UpsertGoalDto) {
    const trainer = await this.trainerOf(userId);
    const relation = await this.prisma.booking.findFirst({
      where: { trainerId: trainer.id, clientId },
    });
    if (!relation) {
      throw new ForbiddenException('Klien ini belum menjadi klien Anda');
    }
    return this.prisma.clientGoal.upsert({
      where: { clientId_trainerId: { clientId, trainerId: trainer.id } },
      create: { clientId, trainerId: trainer.id, ...dto },
      update: { ...dto },
    });
  }

  private async trainerOf(userId: string) {
    const trainer = await this.prisma.trainerProfile.findUnique({
      where: { userId },
    });
    if (!trainer) throw new NotFoundException('Profil trainer tidak ditemukan');
    return trainer;
  }
}
