import { Type } from 'class-transformer';
import { IsInt, IsOptional, IsString, Matches, Max, Min, MinLength } from 'class-validator';

const HHMM = /^([01]\d|2[0-3]):[0-5]\d$/;

export class CreateMealDto {
  @Matches(HHMM, { message: 'Jam harus berformat HH:mm' }) time: string;
  @IsString() @MinLength(2) category: string;
  @IsString() @MinLength(2) description: string;
  @Type(() => Number) @IsInt() @Min(0) @Max(5000) calories: number;
  @Type(() => Number) @IsInt() @Min(0) @Max(500) protein: number;
}

export class UpdateMealDto {
  @IsOptional() @Matches(HHMM, { message: 'Jam harus berformat HH:mm' }) time?: string;
  @IsOptional() @IsString() @MinLength(2) category?: string;
  @IsOptional() @IsString() @MinLength(2) description?: string;
  @IsOptional() @Type(() => Number) @IsInt() @Min(0) @Max(5000) calories?: number;
  @IsOptional() @Type(() => Number) @IsInt() @Min(0) @Max(500) protein?: number;
}
