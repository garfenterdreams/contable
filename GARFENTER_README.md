# Garfenter Contable - Sistema de Contabilidad para Guatemala

Sistema de contabilidad completo basado en Bigcapital Open Source, configurado específicamente para el mercado guatemalteco con soporte para español (es) y Quetzal (GTQ).

## Características

- **Idioma**: Español (es) como idioma predeterminado
- **Moneda**: Quetzal Guatemalteco (GTQ) como moneda predeterminada
- **Zona Horaria**: America/Guatemala
- **Base de Datos**: PostgreSQL 15
- **Arquitectura**: Microservicios con Docker Compose
- **Almacenamiento**: Volúmenes persistentes para datos

## Componentes del Sistema

### Servicios Principales

1. **garfenter-contable** - API Backend (Node.js/NestJS)
   - Puerto: 3000
   - Lógica de negocio y API REST

2. **garfenter-webapp** - Frontend Web (React)
   - Puerto: 4000
   - Interfaz de usuario

3. **garfenter-postgres** - Base de Datos (PostgreSQL 15)
   - Puerto: 5432
   - Almacenamiento de datos principal

4. **garfenter-mongo** - Base de Datos NoSQL (MongoDB)
   - Puerto: 27017
   - Cola de trabajos y tareas programadas

5. **garfenter-redis** - Cache y Sesiones (Redis)
   - Puerto: 6379
   - Caché de aplicación y almacenamiento de sesiones

6. **garfenter-gotenberg** - Generador de PDF
   - Puerto: 3000 (interno)
   - Generación de reportes y documentos PDF

## Requisitos del Sistema

- Docker Engine 20.10 o superior
- Docker Compose V2 o superior
- 4GB de RAM mínimo (8GB recomendado)
- 20GB de espacio en disco
- Sistema operativo: Linux, macOS, o Windows con WSL2

## Instalación Rápida (One-Click)

### 1. Clonar o Descargar el Repositorio

```bash
cd /Users/garfenter/development/products/accounting/bigcapital
```

### 2. Configurar Variables de Entorno

```bash
# El script copiará .env.garfenter.example a .env.garfenter automáticamente
# Edita las variables importantes:
nano .env.garfenter
```

**Variables Críticas a Cambiar:**

```bash
# Seguridad
JWT_SECRET=tu_secreto_jwt_aleatorio_muy_largo
DB_PASSWORD=tu_contraseña_segura_de_base_de_datos

# Admin
AGENDASH_AUTH_PASSWORD=tu_contraseña_admin_segura

# Email (opcional pero recomendado)
MAIL_HOST=smtp.tuservidor.com
MAIL_USERNAME=contable@tuempresa.com
MAIL_PASSWORD=tu_contraseña_email
```

### 3. Iniciar Garfenter Contable

```bash
./garfenter-start.sh start
```

### 4. Acceder al Sistema

Espera unos minutos mientras los servicios se inician. Luego accede a:

- **Aplicación Web**: http://localhost:4000
- **API Backend**: http://localhost:3000
- **Panel de Trabajos**: http://localhost:3000/agendash

## Comandos Disponibles

El script `garfenter-start.sh` proporciona los siguientes comandos:

```bash
# Iniciar todos los servicios
./garfenter-start.sh start

# Detener todos los servicios
./garfenter-start.sh stop

# Reiniciar todos los servicios
./garfenter-start.sh restart

# Ver estado de los servicios
./garfenter-start.sh status

# Ver logs en tiempo real
./garfenter-start.sh logs

# Ver logs de un servicio específico
./garfenter-start.sh logs garfenter-contable
./garfenter-start.sh logs garfenter-webapp

# Limpieza completa (¡elimina todos los datos!)
./garfenter-start.sh cleanup

# Mostrar ayuda
./garfenter-start.sh help
```

## Gestión Manual con Docker Compose

Si prefieres usar Docker Compose directamente:

```bash
# Iniciar servicios
docker compose -f docker-compose.garfenter.yml --env-file .env.garfenter up -d

# Detener servicios
docker compose -f docker-compose.garfenter.yml --env-file .env.garfenter down

# Ver logs
docker compose -f docker-compose.garfenter.yml --env-file .env.garfenter logs -f

# Reconstruir imágenes
docker compose -f docker-compose.garfenter.yml --env-file .env.garfenter build --no-cache
```

## Configuración Avanzada

### Configuración de Email

Para enviar notificaciones y facturas por email:

```bash
MAIL_HOST=smtp.gmail.com
MAIL_USERNAME=tu-email@gmail.com
MAIL_PASSWORD=tu-contraseña-de-aplicacion
MAIL_PORT=587
MAIL_SECURE=false
MAIL_FROM_NAME=Garfenter Contable
MAIL_FROM_ADDRESS=contable@tuempresa.com
```

### Integración Bancaria (Plaid)

Para sincronización automática con bancos:

```bash
BANK_FEED_ENABLED=true
PLAID_ENV=sandbox  # o 'production'
PLAID_CLIENT_ID=tu_client_id
PLAID_SECRET=tu_secret
```

### Almacenamiento S3

Para almacenar documentos en S3 o compatible:

```bash
S3_REGION=us-east-1
S3_ACCESS_KEY_ID=tu_access_key
S3_SECRET_ACCESS_KEY=tu_secret_key
S3_ENDPOINT=https://s3.amazonaws.com
S3_BUCKET=garfenter-contable-docs
```

### Tasas de Cambio

Para obtener tasas de cambio automáticas:

```bash
EXCHANGE_RATE_SERVICE=open-exchange-rate
OPEN_EXCHANGE_RATE_APP_ID=tu_api_key
```

Obtén una API key gratuita en: https://openexchangerates.org/

## Seguridad

### Recomendaciones de Producción

1. **Cambiar Contraseñas**: Modifica todas las contraseñas predeterminadas en `.env.garfenter`
2. **JWT Secret**: Usa una cadena aleatoria larga (mínimo 32 caracteres)
3. **HTTPS**: Configura un proxy reverso (Nginx/Traefik) con SSL/TLS
4. **Firewall**: Cierra puertos innecesarios
5. **Backups**: Configura copias de seguridad automáticas de PostgreSQL
6. **Actualizaciones**: Mantén Docker y las imágenes actualizadas

### Configurar Proxy Reverso (Nginx)

Ejemplo de configuración Nginx para producción:

```nginx
server {
    listen 80;
    server_name contable.tuempresa.com;

    # Redirigir a HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name contable.tuempresa.com;

    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;

    # Frontend
    location / {
        proxy_pass http://localhost:4000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # API Backend
    location /api {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

## Copias de Seguridad

### Backup de PostgreSQL

```bash
# Crear backup
docker exec garfenter-contable-postgres pg_dumpall -U garfenter > backup_$(date +%Y%m%d_%H%M%S).sql

# Restaurar backup
docker exec -i garfenter-contable-postgres psql -U garfenter < backup_20240101_120000.sql
```

### Backup de Volúmenes Docker

```bash
# Backup de todos los volúmenes
docker run --rm \
  -v garfenter_contable_postgres:/data/postgres \
  -v garfenter_contable_mongo:/data/mongo \
  -v garfenter_contable_redis:/data/redis \
  -v $(pwd)/backup:/backup \
  alpine tar czf /backup/garfenter_backup_$(date +%Y%m%d).tar.gz /data
```

## Solución de Problemas

### Los servicios no inician

```bash
# Ver logs detallados
./garfenter-start.sh logs

# Verificar estado de servicios
./garfenter-start.sh status

# Reconstruir imágenes
docker compose -f docker-compose.garfenter.yml build --no-cache
```

### Error de conexión a base de datos

```bash
# Verificar que PostgreSQL está corriendo
docker exec garfenter-contable-postgres pg_isready -U garfenter

# Ver logs de PostgreSQL
docker logs garfenter-contable-postgres
```

### Problemas de permisos

```bash
# Verificar permisos del script
chmod +x garfenter-start.sh

# Verificar permisos de volúmenes
docker volume ls | grep garfenter
```

### Resetear todo el sistema

```bash
# ADVERTENCIA: Esto eliminará todos los datos
./garfenter-start.sh cleanup
```

## Actualización del Sistema

```bash
# 1. Backup de datos
./garfenter-start.sh stop
# Hacer backup de base de datos (ver sección Copias de Seguridad)

# 2. Actualizar código
git pull origin main

# 3. Reconstruir imágenes
docker compose -f docker-compose.garfenter.yml build --no-cache

# 4. Reiniciar servicios
./garfenter-start.sh start
```

## Monitoreo

### Ver Recursos Utilizados

```bash
# Ver uso de recursos de todos los contenedores
docker stats

# Ver uso de recursos de Garfenter
docker stats garfenter-contable-api garfenter-contable-webapp garfenter-contable-postgres
```

### Health Checks

```bash
# API Health
curl http://localhost:3000/api/health

# PostgreSQL Health
docker exec garfenter-contable-postgres pg_isready -U garfenter
```

## Soporte y Contribuciones

Este sistema está basado en **Bigcapital**, un software de contabilidad de código abierto.

- Bigcapital Repository: https://github.com/bigcapitalhq/bigcapital
- Bigcapital Documentation: https://docs.bigcapital.app/

## Licencia

Este proyecto mantiene la licencia del proyecto original Bigcapital.

## Notas Importantes

1. **PostgreSQL vs MariaDB**: Esta versión ha sido adaptada para usar PostgreSQL 15 en lugar de MariaDB. Si experimentas problemas, considera usar la configuración original con MariaDB.

2. **Datos de Prueba**: Al iniciar por primera vez, el sistema no tendrá datos. Necesitarás crear tu primera cuenta de usuario.

3. **Localización**: El sistema está preconfigurado para Guatemala (español, GTQ, zona horaria America/Guatemala).

4. **Producción**: Para uso en producción, asegúrate de:
   - Cambiar todas las contraseñas
   - Configurar HTTPS
   - Configurar backups automáticos
   - Implementar monitoreo
   - Revisar logs regularmente

---

**Garfenter Contable** - Sistema de Contabilidad para Guatemala
Powered by Bigcapital Open Source
