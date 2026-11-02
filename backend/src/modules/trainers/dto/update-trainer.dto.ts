import { IsInt, IsOptional, IsString, Max, Min } from 'class-validator';

export class UpdateTrainerDto {
  @IsOptional() @IsString() specialization?: string;
  @IsOptional() @IsString() bio?: string;
  @IsOptional() @IsInt() @Min(0) @Max(60) experienceYears?: number;
}
