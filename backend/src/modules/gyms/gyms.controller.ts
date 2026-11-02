import { Body, Controller, Get, Param, Patch, Query, UseGuards } from '@nestjs/common';
import { Public } from '../../common/decorators/public.decorator';
import { Roles } from '../../common/decorators/roles.decorator';
import { TenantGuard } from '../../common/guards/tenant.guard';
import { UpdateGymDto } from './dto/update-gym.dto';
import { GymsService } from './gyms.service';

@Controller('gyms')
export class GymsController {
  constructor(private readonly gyms: GymsService) {}

  // Publik: dipakai juga di layar registrasi untuk memilih cabang.
  @Public()
  @Get()
  findAll(@Query('search') search?: string) {
    return this.gyms.findAll(search);
  }

  @Public()
  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.gyms.findOne(id);
  }

  @Roles('ADMIN')
  @UseGuards(TenantGuard)
  @Patch(':id')
  update(@Param('id') id: string, @Body() dto: UpdateGymDto) {
    return this.gyms.update(id, dto);
  }
}
