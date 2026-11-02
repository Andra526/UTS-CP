import { IsOptional, IsString } from 'class-validator';

export class UpdateGymDto {
  @IsOptional() @IsString() address?: string;
  @IsOptional() @IsString() openHours?: string;
  @IsOptional() @IsString() phone?: string;
  @IsOptional() @IsString() imageUrl?: string;
}
