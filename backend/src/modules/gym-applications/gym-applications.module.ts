import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { GymApplicationsController } from './gym-applications.controller';
import { GymApplicationsService } from './gym-applications.service';

@Module({
  imports: [AuthModule],
  controllers: [GymApplicationsController],
  providers: [GymApplicationsService],
})
export class GymApplicationsModule {}
