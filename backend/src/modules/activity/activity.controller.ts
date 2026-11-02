import { Controller, Get } from '@nestjs/common';
import { AuthUser, CurrentUser } from '../../common/decorators/current-user.decorator';
import { Roles } from '../../common/decorators/roles.decorator';
import { ActivityService } from './activity.service';

@Controller('activity')
export class ActivityController {
  constructor(private readonly activity: ActivityService) {}

  @Roles('MEMBER')
  @Get('me')
  mine(@CurrentUser() user: AuthUser) {
    return this.activity.forMember(user.id);
  }
}
