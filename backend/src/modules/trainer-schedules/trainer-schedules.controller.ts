import { Body, Controller, Delete, Get, Param, Post, Query } from '@nestjs/common';
import { AuthUser, CurrentUser } from '../../common/decorators/current-user.decorator';
import { Roles } from '../../common/decorators/roles.decorator';
import { CreateScheduleDto } from './dto/create-schedule.dto';
import { TrainerSchedulesService } from './trainer-schedules.service';

@Controller('trainer-schedules')
export class TrainerSchedulesController {
  constructor(private readonly schedules: TrainerSchedulesService) {}

  /** Jadwal milik PT yang sedang login. */
  @Roles('TRAINER')
  @Get('me')
  findMine(@CurrentUser() user: AuthUser) {
    return this.schedules.findMine(user.id);
  }

  /** Jadwal ketersediaan seorang PT (untuk dipilih member saat booking). */
  @Get()
  findByTrainer(@Query('trainerId') trainerId?: string) {
    return this.schedules.findByTrainer(trainerId);
  }

  @Roles('TRAINER')
  @Post()
  create(@CurrentUser() user: AuthUser, @Body() dto: CreateScheduleDto) {
    return this.schedules.create(user.id, dto);
  }

  @Roles('TRAINER')
  @Delete(':id')
  remove(@CurrentUser() user: AuthUser, @Param('id') id: string) {
    return this.schedules.remove(user.id, id);
  }
}
