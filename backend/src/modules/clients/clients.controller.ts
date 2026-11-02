import { Controller, Get } from '@nestjs/common';
import { AuthUser, CurrentUser } from '../../common/decorators/current-user.decorator';
import { Roles } from '../../common/decorators/roles.decorator';
import { ClientsService } from './clients.service';

@Controller('clients')
@Roles('TRAINER')
export class ClientsController {
  constructor(private readonly clients: ClientsService) {}

  @Get()
  findMine(@CurrentUser() user: AuthUser) {
    return this.clients.findMine(user.id);
  }
}
