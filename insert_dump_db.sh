#!/bin/bash

# HOW USE
# START SCRIPT "sudo ./insert-dump.sh ${FILENAME} "

source config.sh
set -uo pipefail

cd "${PROJECT_PATH_BACKEND}" || {
    echo "ERROR: cannot cd to ${PROJECT_PATH_BACKEND}"
    exit 1
}

stop_activ_sessions_db() {
    echo "INFO: stopping activity sessions db..."

    if ! ${DOCKER_COMPOSE_CMD} exec ${SERVICE_NAME} psql -U ${DB_USER} -c "
        SELECT pg_terminate_backend(pg_stat_activity.pid)
        FROM pg_stat_activity   
        WHERE pg_stat_activity.datname = '${DB_NAME}'
          AND pid <> pg_backend_pid();
    " > /dev/null 2>&1; then
        echo "ERROR: failed to terminate sessions for ${DB_NAME}"
        return 1
    fi
    
    echo "INFO: all sessions terminated for ${DB_NAME}"
}

validate_dump_file() {
    local dump_file="$1"

    if grep -E "^\s*(DROP\s+DATABASE|DROP\s+TABLE.*\b${DB_NAME}\b)" "$dump_file" > /dev/null; then
        echo "ERROR: you can't drop my db, pls stop"
        return 1
    fi 

    if grep -E "^\s*(DELETE\s+FROM|TRUNCATE)" "$dump_file" > /dev/null; then
        echo "ERROR: edit your database in an active session, then load the dump"
        return 1
    fi
}


if [ $# -eq 0 ]; then
    echo "Usage: $0 <file_dump.sql>"
    exit 1
fi

if [[ "$1" != *.sql ]]; then
    echo "ERROR: File must have .sql extension"
    exit 1
fi

if [ ! -f "$DUMP_PATH/$1" ]; then
    echo "ERROR: File not found: $DUMP_PATH/$1"
    exit 1
fi

if ! validate_dump_file "$DUMP_PATH/$1" ; then
    exit 1 
fi

read -p "[y/n] Нажимая 'y' текущая бд ${DB_NAME}, полностью пересоздаться с полным отключением активных сессий, и подстановкой выбранного dump файла: $1: " -r user_input
echo ""

if [[ "$user_input" =~ ^[Yy]$ ]]; then
    ${DOCKER_COMPOSE_CMD} exec -T ${SERVICE_NAME} psql -U ${DB_USER} -d postgres -c "\l" | grep ${DB_NAME} > /dev/null
    exit_code=$?

    echo "INFO: Starting dump insertion from $1"

    if [ $exit_code -eq 0 ]; then
        stop_activ_sessions_db || exit 1
        set -e

        ${DOCKER_COMPOSE_CMD} exec ${SERVICE_NAME} psql -U ${DB_USER} -d postgres -c "DROP DATABASE \"${DB_NAME}\";" > /dev/null
        echo "INFO: DROP DATABASE ${DB_NAME}"

        ${DOCKER_COMPOSE_CMD} exec ${SERVICE_NAME} psql -U ${DB_USER} -d postgres -c "CREATE DATABASE \"${DB_NAME}\";" > /dev/null

        ${DOCKER_COMPOSE_CMD} exec -T ${SERVICE_NAME} psql -U ${DB_USER} -d ${DB_NAME} < "${DUMP_PATH}/$1" > /dev/null
        echo "INFO: CREATE AND INSERT DUMP"

        ${DOCKER_COMPOSE_CMD} restart

        set +e
    else
        exit 1
    fi
fi
