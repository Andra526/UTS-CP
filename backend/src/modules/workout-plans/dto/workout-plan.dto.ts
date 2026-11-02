import { Type } from 'class-transformer';
import { IsInt, IsOptional, IsString, Max, Min, MinLength } from 'class-validator';

export class CreateWorkoutItemDto {
  @IsString() @MinLength(2) dayLabel: string;
  @IsString() @MinLength(2) exercise: string;
  @Type(() => Number) @IsInt() @Min(1) @Max(20) sets: number;
  @IsString() @MinLength(1) reps: string;
  @IsOptional() @Type(() => Number) @IsInt() @Min(0) @Max(900) restSec?: number;
  @IsOptional() @IsString() note?: string;
}

export class UpdateWorkoutItemDto {
  @IsOptional() @IsString() @MinLength(2) dayLabel?: string;
  @IsOptional() @IsString() @MinLength(2) exercise?: string;
  @IsOptional() @Type(() => Number) @IsInt() @Min(1) @Max(20) sets?: number;
  @IsOptional() @IsString() @MinLength(1) reps?: string;
  @IsOptional() @Type(() => Number) @IsInt() @Min(0) @Max(900) restSec?: number;
  @IsOptional() @IsString() note?: string;
}
