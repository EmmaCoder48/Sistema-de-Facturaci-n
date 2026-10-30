-- Rol de la aplicación para que las pruebas ejerzan los privilegios de V1__base.sql.
-- En desarrollo lo crea docker/postgres/init/01-roles.sh.
CREATE ROLE pos_app NOLOGIN;
