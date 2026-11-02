import { IsIn, IsString, Matches } from 'class-validator';
import { DAY_NAMES } from '../../../common/utils/serializers';

export class CreateScheduleDto {
  @IsIn(DAY_NAMES)
  day: string;

  @IsString()
  @Matches(/^([01]\d|2[0-3]):[0-5]\d$/, { message: 'startTime harus HH:mm' })
  startTime: string;

  @IsString()
  @Matches(/^([01]\d|2[0-3]):[0-5]\d$/, { message: 'endTime harus HH:mm' })
  endTime: string;
}
