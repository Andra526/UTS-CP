import { Body, Controller, Post, Req, UploadedFiles, UseInterceptors } from '@nestjs/common';
import { FilesInterceptor } from '@nestjs/platform-express';
import { Public } from '../../common/decorators/public.decorator';
import { imageUploadOptions } from '../../common/utils/upload';
import { RegisterGymDto } from './dto/register-gym.dto';
import { GymApplicationsService } from './gym-applications.service';

@Controller('gym-applications')
export class GymApplicationsController {
  constructor(private readonly service: GymApplicationsService) {}

  /** Publik (multipart/form-data): daftar pemilik + gym baru, field file: "images". */
  @Public()
  @Post()
  @UseInterceptors(FilesInterceptor('images', 6, imageUploadOptions))
  register(
    @Body() dto: RegisterGymDto,
    @UploadedFiles() files: Express.Multer.File[] = [],
    @Req() req: { ip?: string },
  ) {
    return this.service.register(dto, files ?? [], req.ip ?? 'unknown');
  }
}
