import { Module } from '@nestjs/common';
import { TodoModule } from './todo/todo.module';
import { PrismaModule } from './prisma/prisma.module';
import { MetricsModule } from './metrics/metrics.module';
import { HealthModule } from './health/health.module';

@Module({
  imports: [
    PrismaModule,
    TodoModule,
    MetricsModule,
    HealthModule,
  ],
})
export class AppModule {}
