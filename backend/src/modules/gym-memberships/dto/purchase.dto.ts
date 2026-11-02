import { IsString } from 'class-validator';

export class PurchaseMembershipDto {
  @IsString()
  planId: string;
}
