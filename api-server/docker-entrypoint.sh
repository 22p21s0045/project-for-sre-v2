#!/bin/sh
set -e

echo "🔄 Running Prisma migrations..."
bunx prisma migrate deploy

echo "✅ Migrations complete! Starting application..."
exec bun run start:prod
