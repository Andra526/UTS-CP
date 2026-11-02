import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { APP_GUARD } from '@nestjs/core';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { aiConfig } from './config/ai.config';
import { appConfig } from './config/app.config';
import { databaseConfig } from './config/database.config';
import { JwtAuthGuard } from './common/guards/jwt-auth.guard';
import { RolesGuard } from './common/guards/roles.guard';
import { PrismaModule } from './database/prisma/prisma.module';
import { AdminModule } from './modules/admin/admin.module';
import { GymApplicationsModule } from './modules/gym-applications/gym-applications.module';
import { MealPlansModule } from './modules/meal-plans/meal-plans.module';
import { WorkoutPlansModule } from './modules/workout-plans/workout-plans.module';
import { ActivityModule } from './modules/activity/activity.module';
import { SessionPackagesModule } from './modules/session-packages/session-packages.module';
import { AuthModule } from './modules/auth/auth.module';
import { BookingsModule } from './modules/bookings/bookings.module';
import { ClientGoalsModule } from './modules/client-goals/client-goals.module';
import { ClientsModule } from './modules/clients/clients.module';
import { GymMembershipsModule } from './modules/gym-memberships/gym-memberships.module';
import { GymsModule } from './modules/gyms/gyms.module';
import { HealthModule } from './modules/health/health.module';
import { TrainerSchedulesModule } from './modules/trainer-schedules/trainer-schedules.module';
import { TrainersModule } from './modules/trainers/trainers.module';
import { TrainingSessionsModule } from './modules/training-sessions/training-sessions.module';
import { UsersModule } from './modules/users/users.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      load: [appConfig, databaseConfig, aiConfig],
    }),
    PrismaModule,
    AuthModule,
    UsersModule,
    GymsModule,
    GymMembershipsModule,
    ClientsModule,
    TrainersModule,
    TrainerSchedulesModule,
    BookingsModule,
    TrainingSessionsModule,
    ClientGoalsModule,
    HealthModule,
    GymApplicationsModule,
    AdminModule,
    MealPlansModule,
    WorkoutPlansModule,
    ActivityModule,
    SessionPackagesModule,
  ],
  controllers: [AppController],
  providers: [
    AppService,
    { provide: APP_GUARD, useClass: JwtAuthGuard },
    { provide: APP_GUARD, useClass: RolesGuard },
  ],
})
export class AppModule {}
