#!/bin/sh
# Se ejecuta una sola vez, cuando el volumen de datos está vacío.
# Crea la base de datos y los roles de Architecture.md §5.3:
#   pos_owner → dueño del esquema, lo usa Flyway para las migraciones.
#   pos_app   → conexión del backend, sin DELETE (lo asigna V1__base.sql).
set -eu

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname postgres <<EOSQL
CREATE ROLE pos_owner LOGIN PASSWORD '${POS_OWNER_PASSWORD}';
CREATE ROLE pos_app   LOGIN PASSWORD '${POS_APP_PASSWORD}';
CREATE DATABASE ${POS_DB_NAME} OWNER pos_owner ENCODING 'UTF8' TEMPLATE template0;
REVOKE ALL ON DATABASE ${POS_DB_NAME} FROM PUBLIC;
GRANT CONNECT ON DATABASE ${POS_DB_NAME} TO pos_owner, pos_app;
EOSQL

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POS_DB_NAME" <<EOSQL
ALTER SCHEMA public OWNER TO pos_owner;
REVOKE CREATE ON SCHEMA public FROM PUBLIC;
EOSQL
