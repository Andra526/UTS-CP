import { IsIn, IsInt, IsOptional, IsString, Max, Min } from 'class-validator';

export class CreateTrainingSessionDto {
  @IsString()
  bookingId: string;

  @IsIn(['HADIR', 'TERLAMBAT', 'TIDAK_HADIR'])
  attendance: string;

  @IsInt()
  @Min(1)
  @Max(10)
  intensity: number;

  @IsOptional()
  @IsString()
  notes?: string;
}
