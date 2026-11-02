import { SetMetadata } from '@nestjs/common';

export type Role = 'MEMBER' | 'TRAINER' | 'ADMIN';

export const ROLES_KEY = 'roles';
/** Membatasi endpoint untuk role tertentu. */
export const Roles = (...roles: Role[]) => SetMetadata(ROLES_KEY, roles);
