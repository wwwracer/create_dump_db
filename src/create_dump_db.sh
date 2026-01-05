#!/bin/bash
source config.sh

create_dump() {
    cd ${PROJECT_PATH_BACKEND}
    local date=$cur_date

    echo "INFO Starting database dump..."

    if ! ${DOCKER_COMPOSE_CMD} exec -T ${SERVICE_NAME} bash -c "pg_dump -U ${DB_USER} -d ${DB_NAME} > /tmp/dump_db.sql"; then
        echo "ERROR Failed to create database dump"
        return 1
    fi

    if ! docker cp $(${DOCKER_COMPOSE_CMD} ps -q ${SERVICE_NAME}):/tmp/dump_db.sql "${DUMP_PATH}/dump_db_${date}.sql"; then
        echo "ERROR Failed to copy dump to ${DUMP_PATH}"
        return 1
    fi

    ${DOCKER_COMPOSE_CMD} exec -T ${SERVICE_NAME} rm -f /tmp/dump_db.sql

    echo
    echo "INFO✅: create dump out database is success"
}

create_dump