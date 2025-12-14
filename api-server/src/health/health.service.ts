import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class HealthService {
  constructor(private prisma: PrismaService) {}

  async check() {
    const dbStatus = await this.checkDatabase();
    
    return {
      status: dbStatus.status === 'up' ? 'healthy' : 'unhealthy',
      timestamp: new Date().toISOString(),
      services: {
        database: dbStatus,
        api: { status: 'up' },
      },
    };
  }

  async liveness() {
    return {
      status: 'alive',
      timestamp: new Date().toISOString(),
    };
  }

  async readiness() {
    const dbStatus = await this.checkDatabase();
    
    return {
      status: dbStatus.status === 'up' ? 'ready' : 'not_ready',
      timestamp: new Date().toISOString(),
      checks: {
        database: dbStatus,
      },
    };
  }

  private async checkDatabase(): Promise<{ status: string; latency?: number; error?: string }> {
    const start = Date.now();
    
    try {
      await this.prisma.$queryRaw`SELECT 1`;
      const latency = Date.now() - start;
      
      return {
        status: 'up',
        latency,
      };
    } catch (error) {
      return {
        status: 'down',
        error: error.message,
      };
    }
  }
}
