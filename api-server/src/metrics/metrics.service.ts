import { Injectable, OnModuleInit } from '@nestjs/common';
import {
  Registry,
  Counter,
  Histogram,
  Gauge,
  collectDefaultMetrics,
} from 'prom-client';

@Injectable()
export class MetricsService implements OnModuleInit {
  private readonly registry: Registry;

  // Golden Signal: ERROR - Track HTTP errors
  public readonly httpErrorsTotal: Counter<string>;

  // Golden Signal: TRAFFIC - Track total requests
  public readonly httpRequestsTotal: Counter<string>;

  // Golden Signal: LATENCY - Track request duration
  public readonly httpRequestDuration: Histogram<string>;

  // Golden Signal: SATURATION - Track active connections
  public readonly httpActiveConnections: Gauge<string>;

  // Database metrics for saturation
  public readonly dbQueryDuration: Histogram<string>;
  public readonly dbActiveConnections: Gauge<string>;

  constructor() {
    this.registry = new Registry();

    // ERROR: Counter for HTTP errors (4xx and 5xx responses)
    this.httpErrorsTotal = new Counter({
      name: 'http_errors_total',
      help: 'Total number of HTTP errors (4xx and 5xx responses)',
      labelNames: ['method', 'path', 'status_code', 'error_type'],
      registers: [this.registry],
    });

    // TRAFFIC: Counter for all HTTP requests
    this.httpRequestsTotal = new Counter({
      name: 'http_requests_total',
      help: 'Total number of HTTP requests',
      labelNames: ['method', 'path', 'status_code'],
      registers: [this.registry],
    });

    // LATENCY: Histogram for request duration
    this.httpRequestDuration = new Histogram({
      name: 'http_request_duration_seconds',
      help: 'HTTP request duration in seconds',
      labelNames: ['method', 'path', 'status_code'],
      buckets: [0.001, 0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10],
      registers: [this.registry],
    });

    // SATURATION: Gauge for active HTTP connections
    this.httpActiveConnections = new Gauge({
      name: 'http_active_connections',
      help: 'Number of active HTTP connections',
      registers: [this.registry],
    });

    // Database query duration for monitoring DB performance
    this.dbQueryDuration = new Histogram({
      name: 'db_query_duration_seconds',
      help: 'Database query duration in seconds',
      labelNames: ['operation', 'table'],
      buckets: [0.001, 0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1],
      registers: [this.registry],
    });

    // Database connection pool saturation
    this.dbActiveConnections = new Gauge({
      name: 'db_pool_active_connections',
      help: 'Number of active database connections in the pool',
      registers: [this.registry],
    });
  }

  onModuleInit() {
    // Collect default Node.js metrics (memory, CPU, event loop, etc.)
    collectDefaultMetrics({
      register: this.registry,
      prefix: 'nodejs_',
    });

    // Initialize error counter with zero to make it visible in Prometheus
    // even when no errors have occurred yet
    this.httpErrorsTotal.inc(0);
  }

  async getMetrics(): Promise<string> {
    return this.registry.metrics();
  }

  getContentType(): string {
    return this.registry.contentType;
  }

  // Helper method to record a request
  recordRequest(
    method: string,
    path: string,
    statusCode: number,
    durationSeconds: number,
  ): void {
    const labels = {
      method,
      path: this.normalizePath(path),
      status_code: statusCode.toString(),
    };

    // Track all requests (TRAFFIC)
    this.httpRequestsTotal.inc(labels);

    // Track request duration (LATENCY)
    this.httpRequestDuration.observe(labels, durationSeconds);

    // Track errors (ERROR)
    if (statusCode >= 400) {
      const errorType = statusCode >= 500 ? 'server_error' : 'client_error';
      this.httpErrorsTotal.inc({
        ...labels,
        error_type: errorType,
      });
    }
  }

  // Normalize paths to prevent cardinality explosion
  private normalizePath(path: string): string {
    // Replace numeric IDs with :id placeholder
    return path.replace(/\/\d+/g, '/:id');
  }

  incrementActiveConnections(): void {
    this.httpActiveConnections.inc();
  }

  decrementActiveConnections(): void {
    this.httpActiveConnections.dec();
  }
}
