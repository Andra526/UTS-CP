import { IsDateString, IsEmail, IsOptional, IsString, MinLength } from 'class-validator';

/** Data pendaftaran pemilik + cabang gym baru (dari website). */
export class RegisterGymDto {
  @IsString() @MinLength(2) ownerName: string;
  @IsString() @MinLength(2) birthPlace: string;
  @IsDateString() birthDate: string;
  @IsEmail() email: string;
  @IsString() @MinLength(6) password: string;
  @IsOptional() @IsString() phone?: string;

  @IsString() @MinLength(3) gymName: string;
  @IsString() @MinLength(2) city: string;
  @IsString() @MinLength(5) address: string;
  @IsOptional() @IsString() openHours?: string;
}
