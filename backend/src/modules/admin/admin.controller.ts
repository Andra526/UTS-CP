import {
  BadRequestException,
  Body,
  Controller,
  Delete,
  ForbiddenException,
  Get,
  Param,
  Patch,
  Post,
  Query,
  UploadedFiles,
  UseInterceptors,
} from '@nestjs/common';
import { FilesInterceptor } from '@nestjs/platform-express';
import { AuthUser, CurrentUser } from '../../common/decorators/current-user.decorator';
import { Roles } from '../../common/decorators/roles.decorator';
import { imageUploadOptions } from '../../common/utils/upload';
import { AdminService } from './admin.service';
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

/** Seluruh route khusus ADMIN dan otomatis dibatasi ke cabang miliknya (gymId di token). */
@Roles('ADMIN')
@Controller('admin')
export class AdminController {
  constructor(private readonly admin: AdminService) {}

  private gym(user: AuthUser): string {
    if (!user.gymId) throw new ForbiddenException('Akun admin ini belum terhubung ke cabang');
    return user.gymId;
  }

  @Get('dashboard') dashboard(@CurrentUser() u: AuthUser) { return this.admin.dashboard(this.gym(u)); }

  @Get('gym') getGym(@CurrentUser() u: AuthUser) { return this.admin.getGym(this.gym(u)); }
  @Patch('gym') updateGym(@CurrentUser() u: AuthUser, @Body() dto: UpdateMyGymDto) { return this.admin.updateGym(this.gym(u), dto); }

  @Post('gym/facilities') addFacility(@CurrentUser() u: AuthUser, @Body() dto: FacilityDto) { return this.admin.addFacility(this.gym(u), dto); }
  @Patch('gym/facilities/:id') updateFacility(@CurrentUser() u: AuthUser, @Param('id') id: string, @Body() dto: UpdateFacilityDto) { return this.admin.updateFacility(this.gym(u), id, dto); }
  @Delete('gym/facilities/:id') deleteFacility(@CurrentUser() u: AuthUser, @Param('id') id: string) { return this.admin.deleteFacility(this.gym(u), id); }

  @Post('gym/plans') addPlan(@CurrentUser() u: AuthUser, @Body() dto: PlanDto) { return this.admin.addPlan(this.gym(u), dto); }
  @Patch('gym/plans/:id') updatePlan(@CurrentUser() u: AuthUser, @Param('id') id: string, @Body() dto: UpdatePlanDto) { return this.admin.updatePlan(this.gym(u), id, dto); }
  @Delete('gym/plans/:id') deletePlan(@CurrentUser() u: AuthUser, @Param('id') id: string) { return this.admin.deletePlan(this.gym(u), id); }

  @Post('gym/images')
  @UseInterceptors(FilesInterceptor('images', 6, imageUploadOptions))
  addImages(@CurrentUser() u: AuthUser, @UploadedFiles() files: Express.Multer.File[]) {
    if (!files?.length) throw new BadRequestException('Pilih minimal satu gambar');
    return this.admin.addImages(this.gym(u), files);
  }
  @Delete('gym/images/:id') deleteImage(@CurrentUser() u: AuthUser, @Param('id') id: string) { return this.admin.deleteImage(this.gym(u), id); }

  @Get('trainers') listTrainers(@CurrentUser() u: AuthUser) { return this.admin.listTrainers(this.gym(u)); }
  @Post('trainers') createTrainer(@CurrentUser() u: AuthUser, @Body() dto: CreateTrainerDto) { return this.admin.createTrainer(this.gym(u), dto); }
  @Patch('trainers/:id') updateTrainer(@CurrentUser() u: AuthUser, @Param('id') id: string, @Body() dto: UpdateTrainerAdminDto) { return this.admin.updateTrainer(this.gym(u), id, dto); }
  @Delete('trainers/:id') deleteTrainer(@CurrentUser() u: AuthUser, @Param('id') id: string) { return this.admin.deleteTrainer(this.gym(u), id); }

  @Get('memberships') listMemberships(@CurrentUser() u: AuthUser, @Query('status') status?: string) { return this.admin.listMemberships(this.gym(u), status); }
  @Post('memberships') createMembership(@CurrentUser() u: AuthUser, @Body() dto: CreateMembershipDto) { return this.admin.createMembership(this.gym(u), dto); }
  @Patch('memberships/:id') updateMembership(@CurrentUser() u: AuthUser, @Param('id') id: string, @Body() dto: UpdateMembershipDto) { return this.admin.updateMembership(this.gym(u), id, dto); }
  @Delete('memberships/:id') deleteMembership(@CurrentUser() u: AuthUser, @Param('id') id: string) { return this.admin.deleteMembership(this.gym(u), id); }

  @Get('bookings') listBookings(@CurrentUser() u: AuthUser, @Query('status') status?: string) { return this.admin.listBookings(this.gym(u), status); }
  @Patch('bookings/:id') updateBooking(@CurrentUser() u: AuthUser, @Param('id') id: string, @Body() dto: UpdateBookingStatusDto) { return this.admin.updateBooking(this.gym(u), id, dto); }
  @Delete('bookings/:id') deleteBooking(@CurrentUser() u: AuthUser, @Param('id') id: string) { return this.admin.deleteBooking(this.gym(u), id); }
}
