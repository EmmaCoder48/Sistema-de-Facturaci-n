-- Sprint 0: base del esquema. Las tablas de cada épica llegan en las migraciones de su sprint
-- (V2__seguridad.sql, V3__catalogo.sql, ...). Ver Architecture.md §5.

CREATE EXTENSION IF NOT EXISTS pg_trgm;    -- búsqueda por descripción (HU-03.07)
CREATE EXTENSION IF NOT EXISTS unaccent;   -- búsqueda sin tildes (HU-03.07)
CREATE EXTENSION IF NOT EXISTS pgcrypto;   -- gen_random_uuid() y digest() para la bitácora (HU-11.05)

-- unaccent() no es IMMUTABLE, así que no se puede indexar directamente. Este envoltorio sí.
CREATE OR REPLACE FUNCTION f_unaccent(text) RETURNS text
    LANGUAGE sql IMMUTABLE PARALLEL SAFE STRICT
AS $$ SELECT public.unaccent('public.unaccent'::regdictionary, $1) $$;

-- Permisos del rol de la aplicación sobre todo lo que creen las migraciones siguientes.
-- Sin DELETE: los registros se desactivan, no se borran. La bitácora además revocará UPDATE.
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'pos_app') THEN
        GRANT USAGE ON SCHEMA public TO pos_app;
        ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE ON TABLES TO pos_app;
        ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT USAGE, SELECT ON SEQUENCES TO pos_app;
    ELSE
        RAISE NOTICE 'El rol pos_app no existe; no se asignan privilegios por defecto.';
    END IF;
END
$$;
