import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { DAY_NAMES } from '../../common/utils/serializers';
import { PrismaService } from '../../database/prisma/prisma.service';
import { CreateScheduleDto } from './dto/create-schedule.dto';

@Injectable()
export class TrainerSchedulesService {
  constructor(private readonly prisma: PrismaService) {}

  private async trainerIdOf(userId: string) {
    const profile = await this.prisma.trainerProfile.findUnique({
      where: { userId },
    });
    if (!profile) throw new NotFoundException('Profil trainer tidak ditemukan');
    return profile.id;
  }

  async findByTrainer(trainerId?: string) {
    if (!trainerId) throw new BadRequestException('trainerId wajib diisi');
    const list = await this.prisma.trainerSchedule.findMany({
      where: { trainerId },
    });
    return list.sort(
      (a, b) =>
        DAY_NAMES.indexOf(a.day) - DAY_NAMES.indexOf(b.day) ||
        a.startTime.localeCompare(b.startTime),
    );
  }

  async findMine(userId: string) {
    return this.findByTrainer(await this.trainerIdOf(userId));
  }

  async create(userId: string, dto: CreateScheduleDto) {
    if (dto.startTime >= dto.endTime) {
      throw new BadRequestException('Jam selesai harus setelah jam mulai');
    }
    const trainerId = await this.trainerIdOf(userId);
    return this.prisma.trainerSchedule.create({
      data: { trainerId, ...dto },
    });
  }

  async remove(userId: string, id: string) {
    const trainerId = await this.trainerIdOf(userId);
    const slot = await this.prisma.trainerSchedule.findUnique({ where: { id } });
    if (!slot) throw new NotFoundException('Jadwal tidak ditemukan');
    if (slot.trainerId !== trainerId) {
      throw new ForbiddenException('Ini bukan jadwal Anda');
    }
    await this.prisma.trainerSchedule.delete({ where: { id } });
    return { deleted: true };
  }
}
