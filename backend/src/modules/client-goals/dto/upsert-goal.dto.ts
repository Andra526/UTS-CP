import { IsInt, IsOptional, IsString, Max, Min } from 'class-validator';

export class UpsertGoalDto {
  @IsString()
  description: string;

  @IsOptional() @IsInt() @Min(500) @Max(10000) targetCalories?: number;
  @IsOptional() @IsInt() @Min(10) @Max(500) targetProtein?: number;
}
