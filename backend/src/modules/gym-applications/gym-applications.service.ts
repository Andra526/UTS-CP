import { ConflictException, HttpException, HttpStatus, Injectable } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcryptjs';
import { fileUrl, removeUploaded } from '../../common/utils/upload';
import { toPublicUser } from '../../common/utils/serializers';
import { PrismaService } from '../../database/prisma/prisma.service';
import { RegisterGymDto } from './dto/register-gym.dto';

const WINDOW_MS = 60 * 60 * 1000;
const MAX_PER_WINDOW = 10;

@Injectable()
export class GymApplicationsService {
  private readonly hits = new Map<string, number[]>();

  constructor(
    private readonly prisma: PrismaService,
    private readonly jwt: JwtService,
  ) {}

  /** Pembatas sederhana: maks 10 pendaftaran per IP per jam (tanpa super admin = tanpa persetujuan). */
  private throttle(ip: string) {
    const now = Date.now();
    const recent = (this.hits.get(ip) ?? []).filter((t) => now - t < WINDOW_MS);
    if (recent.length >= MAX_PER_WINDOW) {
      throw new HttpException('Terlalu banyak pendaftaran, coba lagi nanti', HttpStatus.TOO_MANY_REQUESTS);
    }
    recent.push(now);
    this.hits.set(ip, recent);
  }

  /** Membuat cabang gym + akun admin-nya sekaligus; langsung tampil di aplikasi HP. */
  async register(dto: RegisterGymDto, files: { filename: string }[], ip: string) {
    const urls = files.map(fileUrl);
    try {
      this.throttle(ip);
      const email = dto.email.trim().toLowerCase();
      if (await this.prisma.user.findUnique({ where: { email } })) {
        throw new ConflictException('Email sudah terdaftar');
      }
      const gymName = dto.gymName.trim();
      if (await this.prisma.gym.findUnique({ where: { name: gymName } })) {
        throw new ConflictException('Nama gym sudah dipakai, tambahkan nama cabang/lokasi');
      }

      const passwordHash = await bcrypt.hash(dto.password, 10);
      const gym = await this.prisma.gym.create({
        data: {
          name: gymName,
          city: dto.city.trim(),
          address: dto.address.trim(),
          openHours: dto.openHours?.trim() || '06.00 - 22.00',
          phone: dto.phone?.trim() || '',
          imageUrl: urls[0] ?? '',
          images: { create: urls.map((url) => ({ url })) },
        },
      });
      const user = await this.prisma.user.create({
        data: {
          name: dto.ownerName.trim(),
          email,
          phone: dto.phone?.trim(),
          passwordHash,
          role: 'ADMIN',
          managedGymId: gym.id,
          birthPlace: dto.birthPlace.trim(),
          birthDate: new Date(dto.birthDate),
        },
      });
      const accessToken = await this.jwt.signAsync({ sub: user.id, role: 'ADMIN', gymId: gym.id });
      return { accessToken, user: toPublicUser(user), gym };
    } catch (e) {
      urls.forEach(removeUploaded); // jangan tinggalkan file yatim bila gagal
      throw e;
    }
  }
}
