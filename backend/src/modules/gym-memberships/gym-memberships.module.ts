import { Module } from '@nestjs/common';
import { GymMembershipsController } from './gym-memberships.controller';
import { GymMembershipsService } from './gym-memberships.service';

@Module({
  controllers: [GymMembershipsController],
  providers: [GymMembershipsService],
  exports: [GymMembershipsService],
})
export class GymMembershipsModule {}
