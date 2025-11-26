#!/bin/bash

# =============================================================================
# Garfenter Contable - One-Click Deployment Script
# Sistema de Contabilidad para Guatemala
# Based on Bigcapital Open Source Accounting Software
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
COMPOSE_FILE="docker-compose.garfenter.yml"
ENV_FILE=".env.garfenter"
ENV_EXAMPLE=".env.garfenter.example"

# Function to print colored messages
print_header() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# ASCII Art Banner
show_banner() {
    echo -e "${MAGENTA}"
    cat << "EOF"
   ____             __            _
  / ___| __ _ _ __ / _| ___ _ __ | |_ ___ _ __
 | |  _ / _` | '__| |_ / _ \ '_ \| __/ _ \ '__|
 | |_| | (_| | |  |  _|  __/ | | | ||  __/ |
  \____|\__,_|_|  |_|  \___|_| |_|\__\___|_|

   ____            _        _     _
  / ___|___  _ __ | |_ __ _| |__ | | ___
 | |   / _ \| '_ \| __/ _` | '_ \| |/ _ \
 | |__| (_) | | | | || (_| | |_) | |  __/
  \____\___/|_| |_|\__\__,_|_.__/|_|\___|

EOF
    echo -e "${NC}"
    echo -e "${CYAN}Sistema de Contabilidad para Guatemala${NC}"
    echo -e "${CYAN}Powered by Bigcapital Open Source${NC}"
    echo ""
}

# Check if Docker is installed
check_docker() {
    print_info "Verificando Docker..."
    if ! command -v docker &> /dev/null; then
        print_error "Docker no está instalado. Por favor instala Docker primero."
        print_info "Visita: https://docs.docker.com/get-docker/"
        exit 1
    fi
    print_success "Docker está instalado"

    print_info "Verificando Docker Compose..."
    if ! docker compose version &> /dev/null; then
        print_error "Docker Compose no está disponible. Por favor instala Docker Compose."
        print_info "Visita: https://docs.docker.com/compose/install/"
        exit 1
    fi
    print_success "Docker Compose está instalado"
}

# Check if .env file exists
check_env_file() {
    print_info "Verificando archivo de configuración..."
    if [ ! -f "$ENV_FILE" ]; then
        if [ -f "$ENV_EXAMPLE" ]; then
            print_warning "Archivo .env no encontrado. Copiando desde $ENV_EXAMPLE..."
            cp "$ENV_EXAMPLE" "$ENV_FILE"
            print_success "Archivo $ENV_FILE creado"
            print_warning "¡IMPORTANTE! Por favor edita el archivo $ENV_FILE con tus configuraciones antes de continuar."
            print_info "Especialmente cambia los siguientes valores:"
            echo "  - JWT_SECRET"
            echo "  - DB_PASSWORD"
            echo "  - AGENDASH_AUTH_PASSWORD"
            echo "  - MAIL_* (configuración de correo)"
            echo ""
            read -p "¿Has editado el archivo .env? (s/n): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[SsYy]$ ]]; then
                print_error "Por favor edita el archivo $ENV_FILE y vuelve a ejecutar este script."
                exit 1
            fi
        else
            print_error "Archivo $ENV_EXAMPLE no encontrado."
            exit 1
        fi
    else
        print_success "Archivo de configuración encontrado"
    fi
}

# Function to start services
start_services() {
    print_header "Iniciando Garfenter Contable"

    print_info "Construyendo imágenes Docker (esto puede tomar varios minutos la primera vez)..."
    docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" build

    print_info "Iniciando servicios..."
    docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" up -d

    print_success "Servicios iniciados exitosamente"
}

# Function to stop services
stop_services() {
    print_header "Deteniendo Garfenter Contable"

    print_info "Deteniendo servicios..."
    docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" down

    print_success "Servicios detenidos"
}

# Function to restart services
restart_services() {
    print_header "Reiniciando Garfenter Contable"

    stop_services
    start_services
}

# Function to show logs
show_logs() {
    print_header "Logs de Garfenter Contable"

    docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" logs -f "$@"
}

# Function to show status
show_status() {
    print_header "Estado de Servicios"

    docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" ps
}

# Function to clean up (stop and remove volumes)
cleanup() {
    print_header "Limpieza Completa de Garfenter Contable"

    print_warning "¡ADVERTENCIA! Esto eliminará todos los datos incluyendo:"
    echo "  - Base de datos"
    echo "  - Archivos subidos"
    echo "  - Configuraciones"
    echo ""
    read -p "¿Estás seguro? (escribe 'si' para confirmar): " -r
    echo
    if [[ $REPLY == "si" ]]; then
        print_info "Deteniendo servicios y eliminando volúmenes..."
        docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" down -v
        print_success "Limpieza completada"
    else
        print_info "Limpieza cancelada"
    fi
}

# Function to show access information
show_access_info() {
    print_header "Información de Acceso"

    # Source the env file to get ports
    if [ -f "$ENV_FILE" ]; then
        source "$ENV_FILE"
    fi

    WEBAPP_PORT=${WEBAPP_PORT:-4000}
    API_PORT=${API_PORT:-3000}
    BASE_URL=${BASE_URL:-http://localhost}

    echo -e "${GREEN}¡Garfenter Contable está ejecutándose!${NC}"
    echo ""
    echo -e "${CYAN}Aplicación Web:${NC}"
    echo -e "  URL: ${GREEN}http://localhost:${WEBAPP_PORT}${NC}"
    echo ""
    echo -e "${CYAN}API Backend:${NC}"
    echo -e "  URL: ${GREEN}http://localhost:${API_PORT}${NC}"
    echo -e "  Health: ${GREEN}http://localhost:${API_PORT}/api/health${NC}"
    echo ""
    echo -e "${CYAN}Panel de Trabajos (Agendash):${NC}"
    echo -e "  URL: ${GREEN}http://localhost:${API_PORT}/agendash${NC}"
    echo -e "  Usuario: ${YELLOW}${AGENDASH_AUTH_USER:-admin}${NC}"
    echo -e "  Contraseña: ${YELLOW}${AGENDASH_AUTH_PASSWORD:-change_this_admin_password}${NC}"
    echo ""
    echo -e "${CYAN}Configuración Regional:${NC}"
    echo -e "  Idioma: ${GREEN}Español (es)${NC}"
    echo -e "  Moneda: ${GREEN}Quetzal Guatemalteco (GTQ)${NC}"
    echo -e "  Zona Horaria: ${GREEN}America/Guatemala${NC}"
    echo ""
    print_info "Para ver los logs en tiempo real, ejecuta:"
    echo "  ./garfenter-start.sh logs"
    echo ""
}

# Function to show help
show_help() {
    print_header "Ayuda - Garfenter Contable"

    echo "Uso: ./garfenter-start.sh [comando]"
    echo ""
    echo "Comandos disponibles:"
    echo "  start     - Iniciar todos los servicios (predeterminado)"
    echo "  stop      - Detener todos los servicios"
    echo "  restart   - Reiniciar todos los servicios"
    echo "  status    - Mostrar estado de los servicios"
    echo "  logs      - Mostrar logs en tiempo real (Ctrl+C para salir)"
    echo "  cleanup   - Detener servicios y eliminar todos los datos"
    echo "  help      - Mostrar esta ayuda"
    echo ""
    echo "Ejemplos:"
    echo "  ./garfenter-start.sh"
    echo "  ./garfenter-start.sh start"
    echo "  ./garfenter-start.sh logs garfenter-contable"
    echo "  ./garfenter-start.sh stop"
    echo ""
}

# Main script
main() {
    show_banner

    COMMAND=${1:-start}

    case $COMMAND in
        start)
            check_docker
            check_env_file
            start_services
            echo ""
            print_info "Esperando a que los servicios estén listos..."
            sleep 10
            show_access_info
            ;;
        stop)
            stop_services
            ;;
        restart)
            check_docker
            restart_services
            echo ""
            print_info "Esperando a que los servicios estén listos..."
            sleep 10
            show_access_info
            ;;
        logs)
            shift
            show_logs "$@"
            ;;
        status)
            show_status
            ;;
        cleanup)
            cleanup
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            print_error "Comando desconocido: $COMMAND"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
