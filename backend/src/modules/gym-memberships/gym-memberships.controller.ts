import { Body, Controller, Get, Post } from '@nestjs/common';
import { AuthUser, CurrentUser } from '../../common/decorators/current-user.decorator';
import { Roles } from '../../common/decorators/roles.decorator';
import { PurchaseMembershipDto } from './dto/purchase.dto';
import { GymMembershipsService } from './gym-memberships.service';

@Controller('memberships')
@Roles('MEMBER')
export class GymMembershipsController {
  constructor(private readonly memberships: GymMembershipsService) {}

  @Post()
  purchase(@CurrentUser() user: AuthUser, @Body() dto: PurchaseMembershipDto) {
    return this.memberships.purchase(user.id, dto.planId);
  }

  @Get('me')
  findMine(@CurrentUser() user: AuthUser) {
    return this.memberships.findMine(user.id);
  }

  @Get('me/active')
  async findActive(@CurrentUser() user: AuthUser) {
    const active = await this.memberships.findActive(user.id);
    return { active };
  }
}
