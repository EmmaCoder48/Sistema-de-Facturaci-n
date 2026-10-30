-- Crea la base de datos y los roles del POS en un PostgreSQL instalado directamente en Windows
-- (sin Docker). Hace lo mismo que docker/postgres/init/01-roles.sh. Ver setup.md, opción B.
--
-- Ejecutar como superusuario desde la carpeta Sistema:
--   psql -U postgres -f scripts\crear-base-local.sql
--
-- Las contraseñas son las de desarrollo (.env.example). Si se cambian aquí, hay que darlas
-- al backend con las variables POS_OWNER_PASSWORD y POS_APP_PASSWORD.

\set ON_ERROR_STOP on

CREATE ROLE pos_owner LOGIN PASSWORD 'pos_owner_dev';
CREATE ROLE pos_app   LOGIN PASSWORD 'pos_app_dev';
CREATE DATABASE pos_db OWNER pos_owner ENCODING 'UTF8' TEMPLATE template0;
REVOKE ALL ON DATABASE pos_db FROM PUBLIC;
GRANT CONNECT ON DATABASE pos_db TO pos_owner, pos_app;

\connect pos_db

ALTER SCHEMA public OWNER TO pos_owner;
REVOKE CREATE ON SCHEMA public FROM PUBLIC;

\echo 'Base de datos pos_db creada con los roles pos_owner y pos_app.'
