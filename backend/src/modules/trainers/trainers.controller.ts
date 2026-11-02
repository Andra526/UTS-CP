import { Body, Controller, Get, Param, Patch, Query } from '@nestjs/common';
import { AuthUser, CurrentUser } from '../../common/decorators/current-user.decorator';
import { Roles } from '../../common/decorators/roles.decorator';
import { UpdateTrainerDto } from './dto/update-trainer.dto';
import { TrainersService } from './trainers.service';

@Controller('trainers')
export class TrainersController {
  constructor(private readonly trainers: TrainersService) {}

  @Get()
  findAll(@Query('gymId') gymId?: string, @Query('search') search?: string) {
    return this.trainers.findAll(gymId, search);
  }

  // Route "me" harus di atas ":id" agar tidak tertangkap sebagai id.
  @Roles('TRAINER')
  @Get('me/dashboard')
  dashboard(@CurrentUser() user: AuthUser) {
    return this.trainers.dashboard(user.id);
  }

  @Roles('TRAINER')
  @Get('me')
  me(@CurrentUser() user: AuthUser) {
    return this.trainers.findByUserId(user.id);
  }

  @Roles('TRAINER')
  @Patch('me')
  updateMe(@CurrentUser() user: AuthUser, @Body() dto: UpdateTrainerDto) {
    return this.trainers.updateMe(user.id, dto);
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.trainers.findOne(id);
  }
}
