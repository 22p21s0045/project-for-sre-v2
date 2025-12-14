# Todo List Project - SRE Golden Signals Practice
# ================================================
# Using Bun as package manager and runtime

.PHONY: help install dev build up down logs clean test db-migrate db-seed monitoring

# Default target
help:
	@echo "Todo List Project - SRE Golden Signals Practice"
	@echo "================================================"
	@echo "Using Bun as package manager and runtime"
	@echo ""
	@echo "Available commands:"
	@echo ""
	@echo "  Development:"
	@echo "    make install        - Install all dependencies"
	@echo "    make dev            - Start development environment (local)"
	@echo "    make dev-api        - Start API server in development mode"
	@echo "    make dev-web        - Start web app in development mode"
	@echo ""
	@echo "  Docker:"
	@echo "    make build          - Build all Docker images"
	@echo "    make up             - Start all services with Docker Compose"
	@echo "    make down           - Stop all services"
	@echo "    make logs           - View all service logs"
	@echo "    make logs-api       - View API server logs"
	@echo "    make logs-web       - View web app logs"
	@echo ""
	@echo "  Database:"
	@echo "    make db-start       - Start PostgreSQL container"
	@echo "    make db-migrate     - Run Prisma migrations"
	@echo "    make db-seed        - Seed database with sample data"
	@echo "    make db-studio      - Open Prisma Studio"
	@echo "    make db-reset       - Reset database (delete all data)"
	@echo ""
	@echo "  Monitoring (SRE):"
	@echo "    make monitoring     - Start monitoring stack (Prometheus + Grafana)"
	@echo "    make monitoring-down- Stop monitoring stack"
	@echo ""
	@echo "  Testing:"
	@echo "    make test           - Run all tests"
	@echo "    make test-api       - Run API server tests"
	@echo ""
	@echo "  Stress Testing:"
	@echo "    make stress-test       - Run stress test (60s, 50 req/s)"
	@echo "    make stress-test-quick - Quick stress test (30s, 30 req/s)"
	@echo "    make stress-test-heavy - Heavy stress test (120s, 100 req/s)"
	@echo "    make stress-test-read  - Read-only stress test"
	@echo "    make stress-test-write - Write stress test"
	@echo "    make stress-test-all   - Full stress test (all endpoints)"
	@echo ""
	@echo "  Cleanup:"
	@echo "    make clean          - Stop and remove all containers and volumes"
	@echo ""
	@echo "  URLs when running:"
	@echo "    - Web App:          http://localhost"
	@echo "    - API Server:       http://localhost:3000"
	@echo "    - API Metrics:      http://localhost:3000/metrics"
	@echo "    - API Health:       http://localhost:3000/health"
	@echo "    - Prometheus:       http://localhost:9090"
	@echo "    - Grafana:          http://localhost:3001 (admin/admin)"

# ==========================================
# Development
# ==========================================

install:
	@echo "📦 Installing API server dependencies..."
	cd api-server && bun install
	@echo "📦 Installing web app dependencies..."
	cd web-app && bun install
	@echo "✅ All dependencies installed!"

dev: db-start
	@echo "🚀 Starting development environment..."
	@echo "Starting API server and web app in parallel..."
	@make -j2 dev-api dev-web

dev-api:
	@echo "🚀 Starting API server..."
	cd api-server && bun run start:dev

dev-web:
	@echo "🚀 Starting web app..."
	cd web-app && bun run dev

# ==========================================
# Docker
# ==========================================

build:
	@echo "🔨 Building all Docker images..."
	docker-compose -f docker-compose.yml build
	@echo "✅ All images built!"

up:
	@echo "🚀 Starting all services..."
	docker-compose -f docker-compose.yml up -d
	@echo ""
	@echo "✅ Services started!"
	@echo "   - Web App:    http://localhost"
	@echo "   - API Server: http://localhost:3000"
	@echo "   - Metrics:    http://localhost:3000/metrics"

down:
	@echo "🛑 Stopping all services..."
	docker-compose -f docker-compose.yml down
	@echo "✅ All services stopped!"

logs:
	docker-compose -f docker-compose.yml logs -f

logs-api:
	docker-compose -f docker-compose.yml logs -f api-server

logs-web:
	docker-compose -f docker-compose.yml logs -f web-app

# ==========================================
# Database
# ==========================================

db-start:
	@echo "🗄️  Starting PostgreSQL..."
	docker-compose -f docker-compose.yml up -d postgres
	@echo "⏳ Waiting for database to be ready..."
	@timeout /t 5 /nobreak > nul 2>&1 || ping -n 6 127.0.0.1 > nul
	@echo "✅ PostgreSQL is ready!"

db-migrate:
	@echo "🔄 Running database migrations..."
	cd api-server && bunx prisma migrate dev
	@echo "✅ Migrations complete!"

db-migrate-deploy:
	@echo "🔄 Deploying database migrations..."
	cd api-server && bunx prisma migrate deploy
	@echo "✅ Migrations deployed!"

db-seed:
	@echo "🌱 Seeding database..."
	cd api-server && bun run prisma:seed
	@echo "✅ Database seeded!"

db-studio:
	@echo "🎨 Opening Prisma Studio..."
	cd api-server && bunx prisma studio

db-reset:
	@echo "⚠️  Resetting database (this will delete all data)..."
	cd api-server && bunx prisma migrate reset --force
	@echo "✅ Database reset complete!"

db-generate:
	@echo "🔄 Generating Prisma client..."
	cd api-server && bunx prisma generate
	@echo "✅ Prisma client generated!"

# ==========================================
# Monitoring (SRE Golden Signals)
# ==========================================

monitoring:
	@echo "📊 Starting monitoring stack (Prometheus + Grafana)..."
	docker-compose -f docker-compose.prod.yml up -d prometheus grafana
	@echo ""
	@echo "✅ Monitoring stack started!"
	@echo "   - Prometheus: http://localhost:9090"
	@echo "   - Grafana:    http://localhost:3001"
	@echo "   - Login:      admin / admin"
	@echo ""
	@echo "📈 Golden Signals Dashboard available in Grafana!"

monitoring-down:
	@echo "🛑 Stopping monitoring stack..."
	docker-compose -f docker-compose.prod.yml down prometheus grafana
	@echo "✅ Monitoring stack stopped!"

# Start everything including monitoring
deploy:
	@echo "🚀 Starting production deployment with monitoring..."
	docker-compose -f docker-compose.prod.yml up -d
	@echo ""
	@echo "✅ All services started!"
	@echo "   - Web App:    http://localhost"
	@echo "   - API Server: http://localhost:3000"
	@echo "   - Metrics:    http://localhost:3000/metrics"
	@echo "   - Prometheus: http://localhost:9090"
	@echo "   - Grafana:    http://localhost:3001 (admin/admin)"

deploy-down:
	@echo "🛑 Stopping production deployment..."
	docker-compose -f docker-compose.prod.yml down
	@echo "✅ All services stopped!"

# ==========================================
# Testing
# ==========================================

test:
	@echo "🧪 Running all tests..."
	@make test-api
	@echo "✅ All tests passed!"

test-api:
	@echo "🧪 Running API server tests..."
	cd api-server && bun test

# ==========================================
# Stress Testing
# ==========================================

# Run stress test with default settings (60s, 50 req/s, mixed tests)
stress-test:
	@echo "🔥 Running stress test..."
	powershell -ExecutionPolicy Bypass -File scripts/stress-test.ps1
	@echo "✅ Stress test complete! Check Grafana for metrics."

# Quick stress test (30s, 30 req/s)
stress-test-quick:
	@echo "🔥 Running quick stress test..."
	powershell -ExecutionPolicy Bypass -File scripts/stress-test.ps1 -Duration 30 -Rate 30
	@echo "✅ Quick stress test complete!"

# Heavy stress test (120s, 100 req/s, 20 concurrent)
stress-test-heavy:
	@echo "🔥 Running heavy stress test..."
	powershell -ExecutionPolicy Bypass -File scripts/stress-test.ps1 -Duration 120 -Rate 100 -Concurrent 20
	@echo "✅ Heavy stress test complete!"

# Read-only stress test
stress-test-read:
	@echo "🔥 Running read-only stress test..."
	powershell -ExecutionPolicy Bypass -File scripts/stress-test.ps1 -TestType read
	@echo "✅ Read-only stress test complete!"

# Write stress test
stress-test-write:
	@echo "🔥 Running write stress test..."
	powershell -ExecutionPolicy Bypass -File scripts/stress-test.ps1 -TestType write
	@echo "✅ Write stress test complete!"

# Full stress test (all endpoints)
stress-test-all:
	@echo "🔥 Running full stress test (all endpoints)..."
	powershell -ExecutionPolicy Bypass -File scripts/stress-test.ps1 -TestType all -Duration 120
	@echo "✅ Full stress test complete!"

# ==========================================
# Cleanup
# ==========================================

clean:
	@echo "🧹 Cleaning up..."
	docker-compose -f docker-compose.yml down -v --remove-orphans
	docker-compose -f docker-compose.prod.yml down -v --remove-orphans
	@echo "✅ Cleanup complete!"

# ==========================================
# Quick commands for SRE practice
# ==========================================

# Generate traffic for testing
traffic:
	@echo "📈 Generating test traffic..."
	@for i in $$(seq 1 100); do \
		curl -s http://localhost:3000/todos > /dev/null; \
		curl -s -X POST http://localhost:3000/todos \
			-H "Content-Type: application/json" \
			-d '{"title":"Test Todo '$$i'"}' > /dev/null; \
	done
	@echo "✅ Traffic generated! Check Grafana for metrics."

# Simulate errors for testing
errors:
	@echo "💥 Simulating errors..."
	@for i in $$(seq 1 20); do \
		curl -s http://localhost:3000/todos/99999 > /dev/null; \
	done
	@echo "✅ Errors simulated! Check Grafana for error rate."
