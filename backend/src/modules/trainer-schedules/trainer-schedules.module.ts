import { Module } from '@nestjs/common';
import { TrainerSchedulesController } from './trainer-schedules.controller';
import { TrainerSchedulesService } from './trainer-schedules.service';

@Module({
  controllers: [TrainerSchedulesController],
  providers: [TrainerSchedulesService],
  exports: [TrainerSchedulesService],
})
export class TrainerSchedulesModule {}
