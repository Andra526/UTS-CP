import { Body, Controller, Delete, Get, Param, Patch, Post } from '@nestjs/common';
import { AuthUser, CurrentUser } from '../../common/decorators/current-user.decorator';
import { Roles } from '../../common/decorators/roles.decorator';
import { CreateMealDto, UpdateMealDto } from './dto/meal-plan.dto';
import { MealPlansService } from './meal-plans.service';

@Controller('meal-plans')
export class MealPlansController {
  constructor(private readonly plans: MealPlansService) {}

  // Member: hanya pola makan miliknya sendiri (tidak ada parameter id).
  @Roles('MEMBER')
  @Get('me')
  mine(@CurrentUser() user: AuthUser) {
    return this.plans.forMember(user.id);
  }

  // PT: kelola pola makan satu klien.
  @Roles('TRAINER')
  @Get('client/:clientId')
  forClient(@CurrentUser() user: AuthUser, @Param('clientId') clientId: string) {
    return this.plans.forClient(user.id, clientId);
  }

  @Roles('TRAINER')
  @Post('client/:clientId')
  create(@CurrentUser() user: AuthUser, @Param('clientId') clientId: string, @Body() dto: CreateMealDto) {
    return this.plans.create(user.id, clientId, dto);
  }

  @Roles('TRAINER')
  @Patch(':id')
  update(@CurrentUser() user: AuthUser, @Param('id') id: string, @Body() dto: UpdateMealDto) {
    return this.plans.update(user.id, id, dto);
  }

  @Roles('TRAINER')
  @Delete(':id')
  remove(@CurrentUser() user: AuthUser, @Param('id') id: string) {
    return this.plans.remove(user.id, id);
  }
}
