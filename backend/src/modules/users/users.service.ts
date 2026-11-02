import { Injectable, NotFoundException } from '@nestjs/common';
import { toPublicUser } from '../../common/utils/serializers';
import { PrismaService } from '../../database/prisma/prisma.service';
import { UpdateUserDto } from './dto/update-user.dto';

@Injectable()
export class UsersService {
  constructor(private readonly prisma: PrismaService) {}

  async getMe(id: string) {
    const user = await this.prisma.user.findUnique({
      where: { id },
      include: { trainerProfile: true },
    });
    if (!user) throw new NotFoundException('User tidak ditemukan');
    return toPublicUser(user);
  }

  async updateMe(id: string, dto: UpdateUserDto) {
    const user = await this.prisma.user.update({
      where: { id },
      data: dto,
      include: { trainerProfile: true },
    });
    return toPublicUser(user);
  }
}
