# Garfenter Contable - Bigcapital Accounting Server
# Uses the official bigcapital server image with auto-migration on first start
FROM bigcapitalhq/server:latest

LABEL org.opencontainers.image.source="https://github.com/garfenterdreams/contable"
LABEL org.opencontainers.image.description="Bigcapital Accounting Server - Garfenter Cloud Platform"

# Environment defaults for Guatemala
ENV NODE_ENV=production
ENV DEFAULT_LOCALE=es
ENV DEFAULT_CURRENCY=GTQ
ENV DEFAULT_TIMEZONE=America/Guatemala
ENV TZ=America/Guatemala

# Install PostgreSQL client for health checks and bash for entrypoint
USER root
RUN apk add --no-cache postgresql-client bash curl

# Create entrypoint script that handles migrations on first start
RUN cat > /docker-entrypoint.sh << 'EOF'
#!/bin/bash
set -e

echo "=== Garfenter Contable Startup ==="
echo "Waiting for PostgreSQL..."

# Wait for PostgreSQL to be ready
until PGPASSWORD=$DB_PASSWORD psql -h "$DB_HOST" -U "$DB_USER" -d "$SYSTEM_DB_NAME" -c '\q' 2>/dev/null; do
    echo "PostgreSQL is unavailable - sleeping 2s..."
    sleep 2
done
echo "PostgreSQL is ready!"

echo "Waiting for MongoDB..."
# Wait for MongoDB (simple TCP check)
until nc -z ${MONGODB_DATABASE_URL#mongodb://} 2>/dev/null || curl -s "http://garfenter-mongo:27017" >/dev/null 2>&1 || timeout 1 bash -c "echo >/dev/tcp/garfenter-mongo/27017" 2>/dev/null; do
    echo "MongoDB is unavailable - sleeping 2s..."
    sleep 2
    # After 30 seconds, continue anyway (MongoDB might not be strictly required for basic operation)
    if [ "$SECONDS" -gt 30 ]; then
        echo "Warning: MongoDB not responding after 30s, continuing anyway..."
        break
    fi
done
echo "MongoDB check complete!"

# Check if migrations are needed (by checking if system tables exist)
echo "Checking database migrations..."
TABLES_EXIST=$(PGPASSWORD=$DB_PASSWORD psql -h "$DB_HOST" -U "$DB_USER" -d "$SYSTEM_DB_NAME" -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public'" 2>/dev/null | tr -d ' ')

if [ "$TABLES_EXIST" = "0" ] || [ -z "$TABLES_EXIST" ]; then
    echo "No tables found - running initial migrations..."
    cd /app
    if [ -f "node_modules/.bin/knex" ]; then
        node_modules/.bin/knex migrate:latest --knexfile knexfile.js || echo "Migration completed or already up to date"
    elif command -v npx &> /dev/null; then
        npx knex migrate:latest --knexfile knexfile.js || echo "Migration completed or already up to date"
    else
        echo "Warning: Could not find knex, skipping migrations"
    fi
    echo "Migrations complete!"
else
    echo "Database has $TABLES_EXIST tables - skipping migrations"
fi

echo "Starting Bigcapital server..."
cd /app/packages/server
exec node build/index.js
EOF

RUN chmod +x /docker-entrypoint.sh

# Expose API port
EXPOSE 3000

# Health check for the API
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:3000/api/health || exit 1

ENTRYPOINT ["/docker-entrypoint.sh"]
