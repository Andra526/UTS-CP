import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
} from '@nestjs/common';

/**
 * Pembatas per-cabang (tenant): Admin Gym hanya boleh mengubah data
 * cabang yang dikelolanya. Dipakai pada route dengan parameter `:id`
 * yang berisi id gym.
 */
@Injectable()
export class TenantGuard implements CanActivate {
  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest();
    const user = request.user;
    const gymId: string | undefined = request.params?.id;

    if (!user || user.role !== 'ADMIN') {
      throw new ForbiddenException('Hanya Admin Gym yang boleh mengubah cabang');
    }
    if (!user.gymId || user.gymId !== gymId) {
      throw new ForbiddenException('Anda hanya boleh mengelola cabang Anda sendiri');
    }
    return true;
  }
}
