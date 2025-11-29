# Garfenter Contable - Bigcapital All-in-One
# Combines webapp (frontend) + server (API) + nginx routing
# Based on official bigcapital images

FROM bigcapitalhq/webapp:latest AS webapp

FROM bigcapitalhq/server:latest AS server

# Final stage - nginx with both apps
FROM nginx:alpine

LABEL org.opencontainers.image.source="https://github.com/garfenterdreams/contable"
LABEL org.opencontainers.image.description="Bigcapital Accounting - Garfenter Cloud Platform"

# Install Node.js, MySQL client, and process manager
RUN apk add --no-cache \
    nodejs \
    npm \
    mysql-client \
    bash \
    curl \
    supervisor

# Copy webapp static files from webapp stage
COPY --from=webapp /usr/share/nginx/html /var/www/webapp

# Copy server from server stage
COPY --from=server /app /app

# Environment defaults for Guatemala
ENV NODE_ENV=production
ENV DEFAULT_LOCALE=es
ENV DEFAULT_CURRENCY=GTQ
ENV DEFAULT_TIMEZONE=America/Guatemala
ENV TZ=America/Guatemala

# Create nginx config that routes / to webapp and /api to server
RUN cat > /etc/nginx/conf.d/default.conf << 'EOF'
server {
    listen 80;
    server_name _;
    root /var/www/webapp;
    index index.html;

    # Frontend (React SPA)
    location / {
        try_files $uri $uri/ /index.html;
    }

    # API routes to Node.js server
    location /api {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        proxy_read_timeout 300s;
    }

    # Static assets with cache
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
EOF

# Create supervisord config to run both nginx and node server
RUN cat > /etc/supervisord.conf << 'EOF'
[supervisord]
nodaemon=true
logfile=/var/log/supervisord.log
pidfile=/var/run/supervisord.pid

[program:nginx]
command=nginx -g "daemon off;"
autostart=true
autorestart=true
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
stderr_logfile=/dev/stderr
stderr_logfile_maxbytes=0

[program:server]
command=/app/docker-entrypoint.sh
directory=/app
autostart=true
autorestart=true
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
stderr_logfile=/dev/stderr
stderr_logfile_maxbytes=0
EOF

# Create entrypoint that handles migrations on first start
RUN cat > /app/docker-entrypoint.sh << 'ENTRYPOINT'
#!/bin/bash
set -e

echo "=== Garfenter Contable Server Startup ==="
echo "Waiting for MySQL..."

# Wait for MySQL to be ready (--skip-ssl for internal network)
until mysql --skip-ssl -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" -e "SELECT 1" > /dev/null 2>&1; do
    echo "MySQL is unavailable - sleeping 2s..."
    sleep 2
done
echo "MySQL is ready!"

echo "Waiting for MongoDB..."
# Wait for MongoDB (simple connectivity check with timeout)
SECONDS=0
until timeout 1 bash -c "echo >/dev/tcp/${MONGODB_HOST:-garfenter-mongo}/27017" 2>/dev/null; do
    echo "MongoDB is unavailable - sleeping 2s..."
    sleep 2
    if [ "$SECONDS" -gt 30 ]; then
        echo "Warning: MongoDB not responding after 30s, continuing..."
        break
    fi
done
echo "MongoDB check complete!"

# Create database if it doesn't exist
echo "Ensuring database exists..."
mysql --skip-ssl -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" -e "CREATE DATABASE IF NOT EXISTS $SYSTEM_DB_NAME CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" 2>/dev/null || true

# Check if migrations are needed
echo "Checking database migrations..."
TABLES_EXIST=$(mysql --skip-ssl -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" -N -s -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = '$SYSTEM_DB_NAME'" 2>/dev/null || echo "0")

if [ "$TABLES_EXIST" = "0" ] || [ -z "$TABLES_EXIST" ]; then
    echo "No tables found - running initial migrations..."
    cd /app/packages/server

    # Create a dynamic knexfile that uses environment variables
    cat > /tmp/knexfile-runtime.js << KNEXEOF
const { knexSnakeCaseMappers } = require('objection');

module.exports = {
  client: 'mysql',
  connection: {
    host: process.env.DB_HOST || 'localhost',
    port: parseInt(process.env.DB_PORT || '3306'),
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '',
    database: process.env.SYSTEM_DB_NAME || 'bigcapital',
    charset: process.env.DB_CHARSET || 'utf8mb4',
  },
  migrations: {
    directory: './src/database/migrations',
  },
  pool: { min: 0, max: 7 },
  ...knexSnakeCaseMappers({ upperCase: true }),
};
KNEXEOF

    echo "Running migrations with host=$DB_HOST database=$SYSTEM_DB_NAME..."
    if [ -f "node_modules/.bin/knex" ]; then
        node_modules/.bin/knex migrate:latest --knexfile /tmp/knexfile-runtime.js || echo "Migration completed or already up to date"
    elif command -v npx &> /dev/null; then
        npx knex migrate:latest --knexfile /tmp/knexfile-runtime.js || echo "Migration completed or already up to date"
    fi
    echo "Migrations complete!"
else
    echo "Database has $TABLES_EXIST tables - skipping migrations"
fi

echo "Starting Bigcapital server on port 3000..."
cd /app/packages/server
exec node build/index.js
ENTRYPOINT

RUN chmod +x /app/docker-entrypoint.sh

# Expose only nginx port
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost/ || exit 1

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
