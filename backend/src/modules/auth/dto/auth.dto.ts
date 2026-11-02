import {
  IsEmail,
  IsIn,
  IsOptional,
  IsString,
  MinLength,
} from 'class-validator';

export class RegisterDto {
  @IsString()
  @MinLength(2)
  name: string;

  @IsEmail()
  email: string;

  @IsString()
  @MinLength(6)
  password: string;

  @IsOptional()
  @IsString()
  phone?: string;

  /** ADMIN tidak bisa mendaftar sendiri (dibuat lewat seed/admin). */
  @IsOptional()
  @IsIn(['MEMBER', 'TRAINER'])
  role?: 'MEMBER' | 'TRAINER';

  /** Wajib untuk TRAINER: cabang tempat bertugas. */
  @IsOptional()
  @IsString()
  gymId?: string;

  @IsOptional()
  @IsString()
  specialization?: string;
}

export class LoginDto {
  /** Email atau nomor HP. */
  @IsString()
  identifier: string;

  @IsString()
  password: string;
}
