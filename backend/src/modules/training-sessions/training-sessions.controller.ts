import { Body, Controller, Get, Post } from '@nestjs/common';
import { AuthUser, CurrentUser } from '../../common/decorators/current-user.decorator';
import { Roles } from '../../common/decorators/roles.decorator';
import { CreateTrainingSessionDto } from './dto/create-session.dto';
import { TrainingSessionsService } from './training-sessions.service';

@Controller('training-sessions')
export class TrainingSessionsController {
  constructor(private readonly sessions: TrainingSessionsService) {}

  @Roles('TRAINER')
  @Post()
  create(@CurrentUser() user: AuthUser, @Body() dto: CreateTrainingSessionDto) {
    return this.sessions.create(user.id, dto);
  }

  /** Riwayat latihan member. */
  @Roles('MEMBER')
  @Get('me')
  findMine(@CurrentUser() user: AuthUser) {
    return this.sessions.findForClient(user.id);
  }

  @Roles('TRAINER')
  @Get('trainer')
  findForTrainer(@CurrentUser() user: AuthUser) {
    return this.sessions.findForTrainer(user.id);
  }
}
