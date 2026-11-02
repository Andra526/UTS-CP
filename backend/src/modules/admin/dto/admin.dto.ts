import { Type } from 'class-transformer';
import { IsBoolean, IsDateString, IsEmail, IsIn, IsInt, IsOptional, IsString, Min, MinLength } from 'class-validator';

export class UpdateMyGymDto {
  @IsOptional() @IsString() @MinLength(3) name?: string;
  @IsOptional() @IsString() city?: string;
  @IsOptional() @IsString() address?: string;
  @IsOptional() @IsString() openHours?: string;
  @IsOptional() @IsString() phone?: string;
}

export class FacilityDto {
  @IsString() @MinLength(2) label: string;
  @IsOptional() @IsString() icon?: string;
}
export class UpdateFacilityDto {
  @IsOptional() @IsString() @MinLength(2) label?: string;
  @IsOptional() @IsString() icon?: string;
}

export class PlanDto {
  @IsString() @MinLength(2) name: string;
  @Type(() => Number) @IsInt() @Min(0) price: number;
  @Type(() => Number) @IsInt() @Min(1) durationDays: number;
  @IsOptional() @IsString() note?: string;
  @IsOptional() @IsBoolean() isPopular?: boolean;
}
export class UpdatePlanDto {
  @IsOptional() @IsString() @MinLength(2) name?: string;
  @IsOptional() @Type(() => Number) @IsInt() @Min(0) price?: number;
  @IsOptional() @Type(() => Number) @IsInt() @Min(1) durationDays?: number;
  @IsOptional() @IsString() note?: string;
  @IsOptional() @IsBoolean() isPopular?: boolean;
}

export class CreateTrainerDto {
  @IsString() @MinLength(2) name: string;
  @IsEmail() email: string;
  @IsString() @MinLength(6) password: string;
  @IsOptional() @IsString() phone?: string;
  @IsString() @MinLength(2) specialization: string;
  @IsOptional() @Type(() => Number) @IsInt() @Min(0) experienceYears?: number;
  @IsOptional() @IsString() bio?: string;
}
export class UpdateTrainerAdminDto {
  @IsOptional() @IsString() @MinLength(2) name?: string;
  @IsOptional() @IsString() phone?: string;
  @IsOptional() @IsString() @MinLength(6) password?: string;
  @IsOptional() @IsString() specialization?: string;
  @IsOptional() @Type(() => Number) @IsInt() @Min(0) experienceYears?: number;
  @IsOptional() @IsString() bio?: string;
  @IsOptional() @IsBoolean() isActive?: boolean;
}

export class CreateMembershipDto {
  @IsString() @MinLength(2) name: string;
  @IsEmail() email: string;
  @IsOptional() @IsString() phone?: string;
  @IsString() planId: string;
}
export class UpdateMembershipDto {
  @IsOptional() @IsIn(['ACTIVE', 'EXPIRED']) status?: 'ACTIVE' | 'EXPIRED';
  @IsOptional() @IsDateString() endDate?: string;
}

export class UpdateBookingStatusDto {
  @IsIn(['ACCEPTED', 'REJECTED', 'CANCELLED']) status: 'ACCEPTED' | 'REJECTED' | 'CANCELLED';
}
