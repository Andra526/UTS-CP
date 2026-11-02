import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../database/prisma/prisma.service';
import { UpdateGymDto } from './dto/update-gym.dto';

@Injectable()
export class GymsService {
  constructor(private readonly prisma: PrismaService) {}

  async findAll(search?: string) {
    const q = search?.trim();
    const gyms = await this.prisma.gym.findMany({
      where: q
        ? { OR: [{ name: { contains: q } }, { city: { contains: q } }] }
        : undefined,
      include: {
        facilities: true,
        images: true,
        plans: { orderBy: { price: 'asc' } },
        _count: { select: { trainers: { where: { isActive: true } } } },
      },
      orderBy: { name: 'asc' },
    });
    return gyms.map(({ _count, ...gym }) => ({
      ...gym,
      trainerCount: _count.trainers,
    }));
  }

  async findOne(id: string) {
    const gym = await this.prisma.gym.findUnique({
      where: { id },
      include: {
        facilities: true,
        images: true,
        plans: { orderBy: { price: 'asc' } },
        _count: { select: { trainers: { where: { isActive: true } } } },
      },
    });
    if (!gym) throw new NotFoundException('Gym tidak ditemukan');
    const { _count, ...rest } = gym;
    return { ...rest, trainerCount: _count.trainers };
  }

  async update(id: string, dto: UpdateGymDto) {
    await this.findOne(id);
    await this.prisma.gym.update({ where: { id }, data: dto });
    return this.findOne(id);
  }
}
