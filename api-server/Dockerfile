# Build stage
FROM oven/bun:1 AS builder

WORKDIR /app

# Copy package files and configs
COPY package.json bun.lock* ./
COPY tsconfig*.json nest-cli.json ./
COPY prisma ./prisma/

# Install all dependencies (including devDependencies for build)
RUN bun install --frozen-lockfile

# Generate Prisma client
RUN bunx prisma generate

# Copy source files
COPY . .

# Build the application
RUN bun run build

# Verify build output exists
RUN ls -la dist/src/ && test -f dist/src/main.js

# Production stage
FROM oven/bun:1-slim AS production

WORKDIR /app

# Copy package files and install production dependencies only
COPY package.json bun.lock* ./
COPY prisma ./prisma/

RUN bun install --production --frozen-lockfile

# Generate Prisma client for production
RUN bunx prisma generate

# Copy built application
COPY --from=builder /app/dist ./dist

# Copy and set up entrypoint script
COPY docker-entrypoint.sh /app/docker-entrypoint.sh
RUN chmod +x /app/docker-entrypoint.sh

# Expose port
EXPOSE 3000

# Use entrypoint script to run migrations before starting
ENTRYPOINT ["/app/docker-entrypoint.sh"]
