import { Injectable } from '@nestjs/common';

@Injectable()
export class AppService {
  info() {
    return { name: 'GymFit API', version: '1.0.0', docs: '/health' };
  }
}
