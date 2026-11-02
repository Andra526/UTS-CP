import {
  BadRequestException,
  ConflictException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcryptjs';
import { toPublicUser } from '../../common/utils/serializers';
import { PrismaService } from '../../database/prisma/prisma.service';
import { LoginDto, RegisterDto } from './dto/auth.dto';

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly jwt: JwtService,
  ) {}

  async register(dto: RegisterDto) {
    const role = dto.role ?? 'MEMBER';
    const email = dto.email.trim().toLowerCase();

    const exists = await this.prisma.user.findUnique({ where: { email } });
    if (exists) throw new ConflictException('Email sudah terdaftar');

    if (role === 'TRAINER') {
      if (!dto.gymId) {
        throw new BadRequestException('Trainer wajib memilih cabang gym');
      }
      const gym = await this.prisma.gym.findUnique({ where: { id: dto.gymId } });
      if (!gym) throw new BadRequestException('Cabang gym tidak ditemukan');
    }

    const passwordHash = await bcrypt.hash(dto.password, 10);
    const user = await this.prisma.user.create({
      data: {
        name: dto.name.trim(),
        email,
        phone: dto.phone,
        passwordHash,
        role,
        ...(role === 'TRAINER'
          ? {
              trainerProfile: {
                create: {
                  gymId: dto.gymId!,
                  specialization:
                    dto.specialization ?? 'Personal Training',
                },
              },
            }
          : {}),
      },
    });

    return this.buildAuthResponse(user.id);
  }

  async login(dto: LoginDto) {
    const identifier = dto.identifier.trim().toLowerCase();
    const user = await this.prisma.user.findFirst({
      where: { OR: [{ email: identifier }, { phone: dto.identifier.trim() }] },
    });
    if (!user || !(await bcrypt.compare(dto.password, user.passwordHash))) {
      throw new UnauthorizedException('Email/No. HP atau password salah');
    }
    return this.buildAuthResponse(user.id);
  }

  async me(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: { trainerProfile: true },
    });
    if (!user) throw new UnauthorizedException('Akun tidak ditemukan');
    return toPublicUser(user);
  }

  private async buildAuthResponse(userId: string) {
    const user = await this.prisma.user.findUniqueOrThrow({
      where: { id: userId },
      include: { trainerProfile: true },
    });
    const gymId = user.trainerProfile?.gymId ?? user.managedGymId ?? null;
    const accessToken = await this.jwt.signAsync({
      sub: user.id,
      role: user.role,
      gymId,
    });
    return { accessToken, user: toPublicUser(user) };
  }
}
