import { Body, Controller, Get, Param, Patch, Post, Query } from '@nestjs/common';
import { AuthUser, CurrentUser } from '../../common/decorators/current-user.decorator';
import { Roles } from '../../common/decorators/roles.decorator';
import { BookingsService } from './bookings.service';
import { CreateBookingDto, ScheduleSessionDto, UpdateBookingStatusDto } from './dto/booking.dto';

@Controller('bookings')
export class BookingsController {
  constructor(private readonly bookings: BookingsService) {}

  @Roles('MEMBER')
  @Post()
  create(@CurrentUser() user: AuthUser, @Body() dto: CreateBookingDto) {
    return this.bookings.create(user.id, dto);
  }

  @Roles('MEMBER')
  @Get('me')
  findMine(@CurrentUser() user: AuthUser) {
    return this.bookings.findForClient(user.id);
  }

  @Roles('TRAINER')
  @Get('trainer')
  findForTrainer(@CurrentUser() user: AuthUser, @Query('status') status?: string) {
    return this.bookings.findForTrainer(user.id, status);
  }

  @Roles('TRAINER')
  @Post('trainer/schedule')
  schedule(@CurrentUser() user: AuthUser, @Body() dto: ScheduleSessionDto) {
    return this.bookings.scheduleByTrainer(user.id, dto);
  }

  @Roles('TRAINER')
  @Patch(':id/status')
  respond(
    @CurrentUser() user: AuthUser,
    @Param('id') id: string,
    @Body() dto: UpdateBookingStatusDto,
  ) {
    return this.bookings.respond(user.id, id, dto.status);
  }

  @Roles('MEMBER')
  @Patch(':id/cancel')
  cancel(@CurrentUser() user: AuthUser, @Param('id') id: string) {
    return this.bookings.cancel(user.id, id);
  }
}
