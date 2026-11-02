import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import * as bcrypt from 'bcryptjs';
import { randomBytes } from 'crypto';
import { fileUrl, removeUploaded } from '../../common/utils/upload';
import { PrismaService } from '../../database/prisma/prisma.service';
import {
  CreateMembershipDto,
  CreateTrainerDto,
  FacilityDto,
  PlanDto,
  UpdateBookingStatusDto,
  UpdateFacilityDto,
  UpdateMembershipDto,
  UpdateMyGymDto,
  UpdatePlanDto,
  UpdateTrainerAdminDto,
} from './dto/admin.dto';

const DAY_MS = 24 * 60 * 60 * 1000;
const userSel = { select: { id: true, name: true, email: true, phone: true, photoUrl: true } };

/** Semua operasi dibatasi ke satu cabang (gymId dari token admin). */
@Injectable()
export class AdminService {
  constructor(private readonly prisma: PrismaService) {}

  // ---------- Dashboard ----------
  async dashboard(gymId: string) {
    const now = new Date();
    const weekStart = new Date(now);
    weekStart.setHours(0, 0, 0, 0);
    weekStart.setDate(weekStart.getDate() - ((weekStart.getDay() + 6) % 7)); // Senin
    const weekEnd = new Date(weekStart.getTime() + 7 * DAY_MS);
    const monthStart = new Date(now.getFullYear(), now.getMonth(), 1);

    await this.expireOld(gymId);
    const trainerFilter = { trainer: { gymId } };
    const [activeMembers, trainers, sessionsThisWeek, revenueAll, revenueMonth, pending, plans, gym] =
      await Promise.all([
        this.prisma.gymMembership
          .findMany({ where: { gymId, status: 'ACTIVE' }, select: { userId: true }, distinct: ['userId'] })
          .then((r) => r.length),
        this.prisma.trainerProfile.count({ where: { gymId, isActive: true } }),
        this.prisma.booking.count({
          where: { ...trainerFilter, status: { in: ['ACCEPTED', 'COMPLETED'] }, scheduledAt: { gte: weekStart, lt: weekEnd } },
        }),
        this.prisma.gymMembership.aggregate({ where: { gymId }, _sum: { price: true } }),
        this.prisma.gymMembership.aggregate({ where: { gymId, startDate: { gte: monthStart } }, _sum: { price: true } }),
        this.prisma.booking.count({ where: { ...trainerFilter, status: 'PENDING' } }),
        this.prisma.gymPlan.count({ where: { gymId } }),
        this.prisma.gym.findUnique({ where: { id: gymId }, include: { images: true } }),
      ]);
    return {
      gymName: gym?.name,
      activeMembers,
      trainers,
      sessionsThisWeek,
      revenueTotal: revenueAll._sum.price ?? 0,
      revenueThisMonth: revenueMonth._sum.price ?? 0,
      pendingBookings: pending,
      checklist: { hasPlans: plans > 0, hasPhotos: (gym?.images.length ?? 0) > 0, hasTrainers: trainers > 0 },
    };
  }

  // ---------- Cabang ----------
  async getGym(gymId: string) {
    const gym = await this.prisma.gym.findUnique({
      where: { id: gymId },
      include: { facilities: true, images: true, plans: { orderBy: { price: 'asc' } } },
    });
    if (!gym) throw new NotFoundException('Cabang tidak ditemukan');
    return gym;
  }

  async updateGym(gymId: string, dto: UpdateMyGymDto) {
    if (dto.name) {
      const dup = await this.prisma.gym.findFirst({ where: { name: dto.name.trim(), NOT: { id: gymId } } });
      if (dup) throw new ConflictException('Nama gym sudah dipakai');
      dto.name = dto.name.trim();
    }
    await this.prisma.gym.update({ where: { id: gymId }, data: dto });
    return this.getGym(gymId);
  }

  async addFacility(gymId: string, dto: FacilityDto) {
    return this.prisma.gymFacility.create({ data: { gymId, label: dto.label.trim(), icon: dto.icon ?? 'fitness' } });
  }
  async updateFacility(gymId: string, id: string, dto: UpdateFacilityDto) {
    await this.own(this.prisma.gymFacility.findFirst({ where: { id, gymId } }), 'Fasilitas');
    return this.prisma.gymFacility.update({ where: { id }, data: dto });
  }
  async deleteFacility(gymId: string, id: string) {
    await this.own(this.prisma.gymFacility.findFirst({ where: { id, gymId } }), 'Fasilitas');
    await this.prisma.gymFacility.delete({ where: { id } });
    return { ok: true };
  }

  async addPlan(gymId: string, dto: PlanDto) {
    return this.prisma.gymPlan.create({
      data: { gymId, name: dto.name.trim(), price: dto.price, durationDays: dto.durationDays, note: dto.note ?? '', isPopular: dto.isPopular ?? false },
    });
  }
  async updatePlan(gymId: string, id: string, dto: UpdatePlanDto) {
    await this.own(this.prisma.gymPlan.findFirst({ where: { id, gymId } }), 'Paket');
    return this.prisma.gymPlan.update({ where: { id }, data: dto });
  }
  async deletePlan(gymId: string, id: string) {
    await this.own(this.prisma.gymPlan.findFirst({ where: { id, gymId } }), 'Paket');
    const used = await this.prisma.gymMembership.count({ where: { planId: id } });
    if (used > 0) {
      throw new ConflictException('Paket sudah dipakai member, tidak bisa dihapus. Ubah harganya atau buat paket baru.');
    }
    await this.prisma.gymPlan.delete({ where: { id } });
    return { ok: true };
  }

  async addImages(gymId: string, files: { filename: string }[]) {
    if (!files.length) throw new BadRequestException('Pilih minimal satu gambar');
    const gym = await this.prisma.gym.findUniqueOrThrow({ where: { id: gymId } });
    const urls = files.map(fileUrl);
    await this.prisma.gymImage.createMany({ data: urls.map((url) => ({ gymId, url })) });
    if (!gym.imageUrl) await this.prisma.gym.update({ where: { id: gymId }, data: { imageUrl: urls[0] } });
    return this.getGym(gymId);
  }
  async deleteImage(gymId: string, id: string) {
    const img = await this.own(this.prisma.gymImage.findFirst({ where: { id, gymId } }), 'Foto');
    await this.prisma.gymImage.delete({ where: { id } });
    removeUploaded(img.url);
    const gym = await this.prisma.gym.findUniqueOrThrow({ where: { id: gymId } });
    if (gym.imageUrl === img.url) {
      const next = await this.prisma.gymImage.findFirst({ where: { gymId }, orderBy: { createdAt: 'asc' } });
      await this.prisma.gym.update({ where: { id: gymId }, data: { imageUrl: next?.url ?? '' } });
    }
    return this.getGym(gymId);
  }

  // ---------- Personal Trainer ----------
  listTrainers(gymId: string) {
    return this.prisma.trainerProfile.findMany({
      where: { gymId },
      include: { user: userSel, _count: { select: { bookings: true } } },
      orderBy: { isActive: 'desc' },
    });
  }

  async createTrainer(gymId: string, dto: CreateTrainerDto) {
    const email = dto.email.trim().toLowerCase();
    if (await this.prisma.user.findUnique({ where: { email } })) throw new ConflictException('Email sudah terdaftar');
    const user = await this.prisma.user.create({
      data: {
        name: dto.name.trim(),
        email,
        phone: dto.phone,
        passwordHash: await bcrypt.hash(dto.password, 10),
        role: 'TRAINER',
        trainerProfile: {
          create: { gymId, specialization: dto.specialization.trim(), experienceYears: dto.experienceYears ?? 0, bio: dto.bio ?? '' },
        },
      },
      include: { trainerProfile: true },
    });
    return this.getTrainer(gymId, user.trainerProfile!.id);
  }

  async getTrainer(gymId: string, id: string) {
    return this.own(
      this.prisma.trainerProfile.findFirst({ where: { id, gymId }, include: { user: userSel, _count: { select: { bookings: true } } } }),
      'Trainer',
    );
  }

  async updateTrainer(gymId: string, id: string, dto: UpdateTrainerAdminDto) {
    const t = await this.getTrainer(gymId, id);
    const { name, phone, password, ...profile } = dto;
    await this.prisma.user.update({
      where: { id: t.userId },
      data: {
        ...(name ? { name: name.trim() } : {}),
        ...(phone !== undefined ? { phone } : {}),
        ...(password ? { passwordHash: await bcrypt.hash(password, 10) } : {}),
      },
    });
    if (Object.keys(profile).length) await this.prisma.trainerProfile.update({ where: { id }, data: profile });
    return this.getTrainer(gymId, id);
  }

  async deleteTrainer(gymId: string, id: string) {
    const t = await this.getTrainer(gymId, id);
    if (t._count.bookings > 0) {
      throw new ConflictException('PT ini punya riwayat booking. Nonaktifkan saja agar riwayat tetap tersimpan.');
    }
    await this.prisma.user.delete({ where: { id: t.userId } }); // profil ikut terhapus (cascade)
    return { ok: true };
  }

  // ---------- Member & membership ----------
  private async expireOld(gymId: string) {
    await this.prisma.gymMembership.updateMany({
      where: { gymId, status: 'ACTIVE', endDate: { lte: new Date() } },
      data: { status: 'EXPIRED' },
    });
  }

  async listMemberships(gymId: string, status?: string) {
    await this.expireOld(gymId);
    const list = await this.prisma.gymMembership.findMany({
      where: { gymId, ...(status ? { status } : {}) },
      include: { user: userSel, plan: { select: { id: true, name: true } } },
      orderBy: { startDate: 'desc' },
    });
    return list.map((m) => ({ ...m, daysLeft: Math.max(0, Math.ceil((m.endDate.getTime() - Date.now()) / DAY_MS)) }));
  }

  /** Daftarkan member langsung di kasir; akun dibuat otomatis bila email belum ada. */
  async createMembership(gymId: string, dto: CreateMembershipDto) {
    const plan = await this.own(this.prisma.gymPlan.findFirst({ where: { id: dto.planId, gymId } }), 'Paket');
    const email = dto.email.trim().toLowerCase();
    let user = await this.prisma.user.findUnique({ where: { email } });
    let temporaryPassword: string | undefined;
    if (user && user.role !== 'MEMBER') throw new ConflictException('Email ini bukan akun member');
    if (!user) {
      temporaryPassword = randomBytes(4).toString('hex');
      user = await this.prisma.user.create({
        data: { name: dto.name.trim(), email, phone: dto.phone, passwordHash: await bcrypt.hash(temporaryPassword, 10), role: 'MEMBER' },
      });
    }
    const start = new Date();
    const membership = await this.prisma.gymMembership.create({
      data: {
        userId: user.id,
        gymId,
        planId: plan.id,
        price: plan.price,
        startDate: start,
        endDate: new Date(start.getTime() + plan.durationDays * DAY_MS),
      },
      include: { user: userSel, plan: { select: { id: true, name: true } } },
    });
    return { membership, temporaryPassword };
  }

  async updateMembership(gymId: string, id: string, dto: UpdateMembershipDto) {
    await this.own(this.prisma.gymMembership.findFirst({ where: { id, gymId } }), 'Membership');
    return this.prisma.gymMembership.update({
      where: { id },
      data: { ...(dto.status ? { status: dto.status } : {}), ...(dto.endDate ? { endDate: new Date(dto.endDate) } : {}) },
      include: { user: userSel, plan: { select: { id: true, name: true } } },
    });
  }

  async deleteMembership(gymId: string, id: string) {
    await this.own(this.prisma.gymMembership.findFirst({ where: { id, gymId } }), 'Membership');
    await this.prisma.gymMembership.delete({ where: { id } });
    return { ok: true };
  }

  // ---------- Booking & sesi ----------
  listBookings(gymId: string, status?: string) {
    return this.prisma.booking.findMany({
      where: { trainer: { gymId }, ...(status ? { status } : {}) },
      include: {
        client: userSel,
        trainer: { select: { id: true, user: { select: { name: true } } } },
        session: true,
      },
      orderBy: { scheduledAt: 'desc' },
      take: 200,
    });
  }

  async updateBooking(gymId: string, id: string, dto: UpdateBookingStatusDto) {
    const b = await this.own(this.prisma.booking.findFirst({ where: { id, trainer: { gymId } } }), 'Booking');
    if (['COMPLETED', 'CANCELLED', 'REJECTED'].includes(b.status)) {
      throw new BadRequestException('Booking ini sudah selesai/ditutup');
    }
    return this.prisma.booking.update({ where: { id }, data: { status: dto.status } });
  }

  async deleteBooking(gymId: string, id: string) {
    await this.own(this.prisma.booking.findFirst({ where: { id, trainer: { gymId } } }), 'Booking');
    await this.prisma.booking.delete({ where: { id } });
    return { ok: true };
  }

  private async own<T>(p: Promise<T | null>, label: string): Promise<T> {
    const r = await p;
    if (!r) throw new NotFoundException(`${label} tidak ditemukan di cabang Anda`);
    return r;
  }
}
