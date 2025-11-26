-- Garfenter Contable - PostgreSQL Initialization Script
-- Sistema de Contabilidad para Guatemala

-- Set timezone to Guatemala
SET timezone = 'America/Guatemala';

-- Create additional extensions if needed
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- Configure PostgreSQL for better performance with accounting workloads
-- These settings can be adjusted based on available resources

-- Log connections
ALTER SYSTEM SET log_connections = 'on';
ALTER SYSTEM SET log_disconnections = 'on';

-- Improve query performance
ALTER SYSTEM SET shared_buffers = '256MB';
ALTER SYSTEM SET effective_cache_size = '1GB';
ALTER SYSTEM SET maintenance_work_mem = '64MB';
ALTER SYSTEM SET checkpoint_completion_target = 0.9;
ALTER SYSTEM SET wal_buffers = '16MB';
ALTER SYSTEM SET default_statistics_target = 100;
ALTER SYSTEM SET random_page_cost = 1.1;
ALTER SYSTEM SET effective_io_concurrency = 200;

-- Set locale for Guatemala
ALTER DATABASE garfenter_system SET lc_messages TO 'es_GT.UTF-8';
ALTER DATABASE garfenter_system SET lc_monetary TO 'es_GT.UTF-8';
ALTER DATABASE garfenter_system SET lc_numeric TO 'es_GT.UTF-8';
ALTER DATABASE garfenter_system SET lc_time TO 'es_GT.UTF-8';

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE garfenter_system TO garfenter;

-- Select the system database
\c garfenter_system;

-- Create schema if needed
CREATE SCHEMA IF NOT EXISTS public;
GRANT ALL ON SCHEMA public TO garfenter;
GRANT ALL ON SCHEMA public TO public;

-- Welcome message
DO $$
BEGIN
    RAISE NOTICE 'Garfenter Contable - Base de datos inicializada correctamente';
    RAISE NOTICE 'Configuración regional: Guatemala (es_GT)';
    RAISE NOTICE 'Zona horaria: America/Guatemala';
    RAISE NOTICE 'Moneda predeterminada: GTQ (Quetzal)';
END $$;
