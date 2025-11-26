# Garfenter Contable - Guía de Inicio Rápido

## Inicio en 3 Pasos

### Paso 1: Configurar Variables de Entorno

```bash
cd /Users/garfenter/development/products/accounting/bigcapital

# Copiar archivo de ejemplo (se hace automáticamente al ejecutar el script)
cp .env.garfenter.example .env.garfenter

# Editar configuración IMPORTANTE
nano .env.garfenter
```

**Cambios Mínimos Requeridos:**

```bash
# Cambia estos valores por seguridad:
JWT_SECRET=genera_un_string_aleatorio_muy_largo_aqui
DB_PASSWORD=tu_password_segura_de_base_de_datos
AGENDASH_AUTH_PASSWORD=password_para_panel_admin
```

### Paso 2: Ejecutar el Script de Inicio

```bash
./garfenter-start.sh start
```

El script:
- Verificará que Docker esté instalado
- Construirá las imágenes Docker
- Iniciará todos los servicios
- Mostrará la información de acceso

### Paso 3: Acceder al Sistema

Después de 1-2 minutos, accede a:

**Aplicación Web**: http://localhost:4000

## Información de Configuración

### Puertos Predeterminados

- **Frontend Web**: 4000
- **Backend API**: 3000
- **PostgreSQL**: 5432 (solo localhost)
- **MongoDB**: 27017 (solo localhost)
- **Redis**: 6379 (solo localhost)

### Configuración Regional

- **Idioma**: Español (es)
- **Moneda**: Quetzal (GTQ)
- **Zona Horaria**: America/Guatemala

### Panel de Administración

**Agendash** (Monitor de trabajos): http://localhost:3000/agendash
- Usuario: `admin` (configurable en .env)
- Contraseña: Ver `AGENDASH_AUTH_PASSWORD` en tu archivo `.env.garfenter`

## Comandos Útiles

```bash
# Ver estado
./garfenter-start.sh status

# Ver logs en tiempo real
./garfenter-start.sh logs

# Reiniciar
./garfenter-start.sh restart

# Detener
./garfenter-start.sh stop
```

## Primer Uso

1. Accede a http://localhost:4000
2. Crea tu cuenta de administrador
3. Configura tu empresa:
   - Nombre de la empresa
   - Moneda: GTQ (Quetzal)
   - Idioma: Español
   - Zona horaria: America/Guatemala
4. ¡Comienza a usar el sistema!

## Solución Rápida de Problemas

### Error: "Docker no está instalado"
```bash
# Instalar Docker Desktop:
# macOS: https://docs.docker.com/desktop/install/mac-install/
# Linux: https://docs.docker.com/engine/install/
```

### Error: "Puerto ya en uso"
```bash
# Cambiar puertos en .env.garfenter:
API_PORT=3001    # Cambiar de 3000 a 3001
WEBAPP_PORT=4001 # Cambiar de 4000 a 4001
```

### Los servicios no inician
```bash
# Ver qué está fallando:
./garfenter-start.sh logs

# Reconstruir todo:
docker compose -f docker-compose.garfenter.yml down
docker compose -f docker-compose.garfenter.yml build --no-cache
./garfenter-start.sh start
```

### Resetear completamente
```bash
# ADVERTENCIA: Elimina todos los datos
./garfenter-start.sh cleanup
./garfenter-start.sh start
```

## Siguiente: Configuración Avanzada

Para configuración detallada de email, S3, integraciones bancarias, etc., consulta el archivo `GARFENTER_README.md`.

---

¿Problemas? Revisa los logs: `./garfenter-start.sh logs`
