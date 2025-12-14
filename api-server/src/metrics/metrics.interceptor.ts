import {
  Injectable,
  NestInterceptor,
  ExecutionContext,
  CallHandler,
} from '@nestjs/common';
import { Observable } from 'rxjs';
import { tap } from 'rxjs/operators';
import { MetricsService } from './metrics.service';

@Injectable()
export class MetricsInterceptor implements NestInterceptor {
  constructor(private readonly metricsService: MetricsService) {}

  intercept(context: ExecutionContext, next: CallHandler): Observable<any> {
    const request = context.switchToHttp().getRequest();
    const response = context.switchToHttp().getResponse();
    const startTime = Date.now();

    // Track active connections (SATURATION)
    this.metricsService.incrementActiveConnections();

    return next.handle().pipe(
      tap({
        next: () => {
          this.recordMetrics(request, response.statusCode, startTime);
        },
        error: (error) => {
          const statusCode = error?.status || 500;
          this.recordMetrics(request, statusCode, startTime);
        },
      }),
    );
  }

  private recordMetrics(
    request: any,
    statusCode: number,
    startTime: number,
  ): void {
    const durationSeconds = (Date.now() - startTime) / 1000;
    
    this.metricsService.recordRequest(
      request.method,
      request.route?.path || request.path,
      statusCode,
      durationSeconds,
    );

    // Decrement active connections
    this.metricsService.decrementActiveConnections();
  }
}
