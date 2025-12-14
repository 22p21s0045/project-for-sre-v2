# Todo List - SRE Golden Signals Practice

A simple Todo List application built with React, NestJS, PostgreSQL, and Prisma, designed for practicing **Site Reliability Engineering (SRE)** concepts with a focus on the **Golden Signals**.

## 🎯 Golden Signals

This project implements monitoring for all four Golden Signals:

| Signal | Description | Metric |
|--------|-------------|--------|
| **Error** | Rate of failed requests | `http_errors_total` |
| **Traffic** | Total requests per second | `http_requests_total` |
| **Latency** | Response time distribution | `http_request_duration_seconds` |
| **Saturation** | Resource utilization | `http_active_connections` |

## 🛠️ Tech Stack

- **Frontend**: React 18 with Vite
- **Backend**: NestJS with TypeScript
- **Database**: PostgreSQL 15
- **ORM**: Prisma
- **Runtime**: Bun
- **Metrics**: Prometheus + prom-client
- **Visualization**: Grafana
- **Containerization**: Docker & Docker Compose

## 🚀 Quick Start

### Prerequisites

- Bun 1.0+
- Docker & Docker Compose
- Make (optional, but recommended)

### Option 1: Using Docker (Recommended)

```bash
# Start all services
make up

# Or with monitoring stack
make deploy
```

### Option 2: Local Development

```bash
# Install dependencies
make install

# Start PostgreSQL
make db-start

# Run migrations
make db-migrate

# Seed database (optional)
make db-seed

# Start development servers
make dev
```

## 📊 Accessing Services

| Service | URL | Description |
|---------|-----|-------------|
| Web App | http://localhost | React frontend |
| API Server | http://localhost:3000 | NestJS backend |
| Metrics | http://localhost:3000/metrics | Prometheus metrics |
| Health Check | http://localhost:3000/health | Health status |
| Prometheus | http://localhost:9090 | Metrics collection |
| Grafana | http://localhost:3001 | Dashboards (admin/admin) |

## 📈 Available Makefile Commands

```bash
make help              # Show all available commands

# Development
make install           # Install dependencies
make dev               # Start development environment
make dev-api           # Start API server only
make dev-web           # Start web app only

# Docker
make build             # Build Docker images
make up                # Start services
make down              # Stop services
make logs              # View logs

# Database
make db-migrate        # Run migrations
make db-seed           # Seed sample data
make db-studio         # Open Prisma Studio
make db-reset          # Reset database

# Monitoring
make monitoring        # Start Prometheus + Grafana
make deploy            # Start all with monitoring
make traffic           # Generate test traffic
make errors            # Simulate errors for testing

# Cleanup
make clean             # Remove all containers and volumes
```

## 🔍 API Endpoints

### Todos

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/todos` | Get all todos |
| GET | `/todos/:id` | Get todo by ID |
| POST | `/todos` | Create new todo |
| PATCH | `/todos/:id` | Update todo |
| PATCH | `/todos/:id/toggle` | Toggle completion |
| DELETE | `/todos/:id` | Delete todo |

### Health & Metrics

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/health` | Health check |
| GET | `/health/live` | Liveness probe |
| GET | `/health/ready` | Readiness probe |
| GET | `/metrics` | Prometheus metrics |

## 📊 Prometheus Queries

### Golden Signals Queries

```promql
# Error Rate
sum(rate(http_errors_total[5m])) / sum(rate(http_requests_total[5m]))

# Traffic (requests per second)
sum(rate(http_requests_total[5m]))

# Latency (P99)
histogram_quantile(0.99, sum(rate(http_request_duration_seconds_bucket[5m])) by (le))

# Saturation
http_active_connections
```

## 📁 Project Structure

```
project-for-sre/
├── api-server/              # NestJS Backend
│   ├── src/
│   │   ├── health/          # Health check module
│   │   ├── metrics/         # Prometheus metrics module
│   │   ├── prisma/          # Prisma service
│   │   └── todo/            # Todo CRUD module
│   ├── prisma/
│   │   └── schema.prisma    # Database schema
│   └── Dockerfile
├── web-app/                 # React Frontend
│   ├── src/
│   │   ├── components/      # React components
│   │   └── services/        # API services
│   └── Dockerfile
├── monitoring/              # Monitoring configuration
│   ├── prometheus.yml       # Prometheus config
│   └── grafana/             # Grafana provisioning
├── docker-compose.yml       # Development compose
├── docker-compose.prod.yml  # Production compose with monitoring
├── Makefile                 # Project commands
└── README.md
```

## 🎓 SRE Practice Exercises

1. **Monitor Error Rate**: Trigger 404 errors using `make errors` and observe the error rate in Grafana.

2. **Analyze Latency**: Generate traffic with `make traffic` and analyze the P50, P90, P99 latency distribution.

3. **Traffic Patterns**: Create and delete todos to see how traffic patterns change over time.

4. **Saturation Testing**: Use load testing tools to increase concurrent connections and observe saturation metrics.

## 📝 License

MIT
