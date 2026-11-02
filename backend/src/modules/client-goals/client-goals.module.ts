import { Module } from '@nestjs/common';
import { ClientGoalsController } from './client-goals.controller';
import { ClientGoalsService } from './client-goals.service';

@Module({
  controllers: [ClientGoalsController],
  providers: [ClientGoalsService],
})
export class ClientGoalsModule {}
