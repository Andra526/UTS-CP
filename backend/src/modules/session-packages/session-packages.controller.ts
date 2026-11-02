import { Body, Controller, Get, Param, Post } from '@nestjs/common';
import { AuthUser, CurrentUser } from '../../common/decorators/current-user.decorator';
import { Roles } from '../../common/decorators/roles.decorator';
import { AddQuotaDto } from './dto/session-package.dto';
import { SessionPackagesService } from './session-packages.service';

@Controller('session-packages')
export class SessionPackagesController {
  constructor(private readonly packages: SessionPackagesService) {}

  // ---- Member ----
  @Roles('MEMBER')
  @Get('me')
  mine(@CurrentUser() user: AuthUser) {
    return this.packages.forMember(user.id);
  }

  @Roles('MEMBER')
  @Get('me/trainer/:trainerId')
  withTrainer(@CurrentUser() user: AuthUser, @Param('trainerId') trainerId: string) {
    return this.packages.memberWithTrainer(user.id, trainerId);
  }

  // ---- PT ----
  @Roles('TRAINER')
  @Get('client/:clientId')
  forClient(@CurrentUser() user: AuthUser, @Param('clientId') clientId: string) {
    return this.packages.forClient(user.id, clientId);
  }

  @Roles('TRAINER')
  @Post('client/:clientId/add')
  add(
    @CurrentUser() user: AuthUser,
    @Param('clientId') clientId: string,
    @Body() dto: AddQuotaDto,
  ) {
    return this.packages.addQuota(user.id, clientId, dto.amount);
  }
}
