#!/bin/bash
cur_date=$(date "+%Y-%m-%d_%H:%M:%S")

check_sudo() {
    if [ -z "$SUDO_USER" ]; then
        echo "ERROR: script must be run with sudo!"
        echo "INFO: use sudo $0"
        exit 1
    fi
}

load_env() {
    if [ -f .env ]; then
        source ./.env
        echo "INFO: .env loaded"
    else 
        echo "ERROR: not found .env file" >&2
        exit 1
    fi

    : ${SERVICE_NAME:="db"}
    : ${DM_PORT:="5432"}
}

check_docker_compose() {
    # echo "INFO: Checking Docker compose availability..."

    if ! docker --version >/dev/null 2>&1; then
        echo "ERROR: docker don't install "
    fi

    if docker compose version >/dev/null 2>&1; then
        DOCKER_COMPOSE_CMD="docker compose"
        echo "INFO: Docker Compose command found: $DOCKER_COMPOSE_CMD"
        return 0
    fi
    
    if docker-compose version >/dev/null 2>&1; then
        DOCKER_COMPOSE_CMD="docker-compose"
        echo "INFO: Docker Compose command found: $DOCKER_COMPOSE_CMD"
        return 0
    fi

    echo "ERROR: Docker Compose not found"
    echo "INFO: install Docker Compose on your system"
    exit 1
}


prepare_dir() {
    if  mkdir -p "${DUMP_PATH}"; then
        echo "INFO: selected paths is create" 
    else 
        echo "ERROR: selected paths can't create"
    fi
}

check_sudo
load_env
prepare_dir
check_docker_compose