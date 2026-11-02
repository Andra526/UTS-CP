import { Body, Controller, Delete, Get, Param, Patch, Post } from '@nestjs/common';
import { AuthUser, CurrentUser } from '../../common/decorators/current-user.decorator';
import { Roles } from '../../common/decorators/roles.decorator';
import { CreateWorkoutItemDto, UpdateWorkoutItemDto } from './dto/workout-plan.dto';
import { WorkoutPlansService } from './workout-plans.service';

@Controller('workout-plans')
export class WorkoutPlansController {
  constructor(private readonly plans: WorkoutPlansService) {}

  // ---- Member ----
  @Roles('MEMBER')
  @Get('me')
  mine(@CurrentUser() user: AuthUser) {
    return this.plans.forMember(user.id);
  }

  @Roles('MEMBER')
  @Post('me/:itemId/done')
  done(@CurrentUser() user: AuthUser, @Param('itemId') itemId: string) {
    return this.plans.markDone(user.id, itemId);
  }

  @Roles('MEMBER')
  @Delete('me/:itemId/done')
  undo(@CurrentUser() user: AuthUser, @Param('itemId') itemId: string) {
    return this.plans.undoDone(user.id, itemId);
  }

  // ---- PT ----
  @Roles('TRAINER')
  @Get('client/:clientId')
  forClient(@CurrentUser() user: AuthUser, @Param('clientId') clientId: string) {
    return this.plans.forClient(user.id, clientId);
  }

  @Roles('TRAINER')
  @Post('client/:clientId')
  create(
    @CurrentUser() user: AuthUser,
    @Param('clientId') clientId: string,
    @Body() dto: CreateWorkoutItemDto,
  ) {
    return this.plans.create(user.id, clientId, dto);
  }

  @Roles('TRAINER')
  @Patch(':id')
  update(@CurrentUser() user: AuthUser, @Param('id') id: string, @Body() dto: UpdateWorkoutItemDto) {
    return this.plans.update(user.id, id, dto);
  }

  @Roles('TRAINER')
  @Delete(':id')
  remove(@CurrentUser() user: AuthUser, @Param('id') id: string) {
    return this.plans.remove(user.id, id);
  }
}
