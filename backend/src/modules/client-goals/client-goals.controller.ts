import { Body, Controller, Get, Param, Put } from '@nestjs/common';
import { AuthUser, CurrentUser } from '../../common/decorators/current-user.decorator';
import { Roles } from '../../common/decorators/roles.decorator';
import { ClientGoalsService } from './client-goals.service';
import { UpsertGoalDto } from './dto/upsert-goal.dto';

@Controller('client-goals')
export class ClientGoalsController {
  constructor(private readonly goals: ClientGoalsService) {}

  @Roles('MEMBER', 'TRAINER')
  @Get(':clientId')
  find(@CurrentUser() user: AuthUser, @Param('clientId') clientId: string) {
    return this.goals.find(user, clientId);
  }

  @Roles('TRAINER')
  @Put(':clientId')
  upsert(
    @CurrentUser() user: AuthUser,
    @Param('clientId') clientId: string,
    @Body() dto: UpsertGoalDto,
  ) {
    return this.goals.upsert(user.id, clientId, dto);
  }
}
