-- ============================================================================
-- V2__seguridad_bitacora.sql  (Sprint 1)
-- EP-01 Seguridad y usuarios, HU-12.05 Cajas, EP-11 Bitácora inmodificable.
-- Se ejecuta con pos_owner (Flyway). La aplicación usa pos_app.
-- Ubicación: backend/src/main/resources/db/migration/
-- Revisar contra V1__base.sql: si V1 ya creó algo de esto, quitar el duplicado.
-- ============================================================================
 
CREATE EXTENSION IF NOT EXISTS pgcrypto;   -- digest() para el hash de la bitácora
 
-- ===== EP-01: roles y permisos =====
CREATE TABLE rol (
  id      smallint PRIMARY KEY,
  codigo  text UNIQUE NOT NULL CHECK (codigo IN ('ADMIN','SUPERVISOR','CAJERO')),
  nombre  text NOT NULL
);
 
CREATE TABLE permiso (
  codigo           text PRIMARY KEY,
  modulo           text NOT NULL,
  descripcion      text NOT NULL,
  exclusivo_admin  boolean NOT NULL DEFAULT false      -- HU-01.10 crit. 4
);
 
CREATE TABLE rol_permiso (
  rol_id   smallint NOT NULL REFERENCES rol(id),
  permiso  text     NOT NULL REFERENCES permiso(codigo),
  PRIMARY KEY (rol_id, permiso)
);
 
INSERT INTO rol (id, codigo, nombre) VALUES
  (1, 'ADMIN',      'Administrador'),
  (2, 'SUPERVISOR', 'Supervisor'),
  (3, 'CAJERO',     'Cajero');
 
-- Matriz inicial de permisos (final de userStoriesE1.md)
INSERT INTO permiso (codigo, modulo, descripcion, exclusivo_admin) VALUES
  ('VENTA_REGISTRAR',          'ventas',        'Registrar ventas', false),
  ('VENTA_SUSPENDER_CANCELAR', 'ventas',        'Suspender y cancelar ventas en curso', false),
  ('PAGO_REGISTRAR',           'pagos',         'Registrar pagos con tarjeta', false),
  ('CLIENTE_GESTIONAR',        'clientes',      'Registrar y editar clientes', false),
  ('FACTURA_REIMPRIMIR',       'facturacion',   'Reimprimir facturas', false),
  ('FACTURA_ANULAR',           'facturacion',   'Anular facturas', false),
  ('CAJA_PROPIA',              'caja',          'Abrir y cerrar su propia caja', false),
  ('CAJA_CERRAR_OTRO',         'caja',          'Cerrar la caja de otro usuario', false),
  ('CAJA_VER_CIERRES_OTROS',   'caja',          'Ver cierres de caja de otros usuarios', false),
  ('REPORTE_CONSULTAR',        'reportes',      'Consultar reportes', false),
  ('BITACORA_CONSULTAR',       'bitacora',      'Consultar la bitácora', false),
  ('PRODUCTO_CONSULTAR',       'catalogo',      'Consultar el catálogo de productos', false),
  ('PRODUCTO_EDITAR',          'catalogo',      'Crear productos y cambiar precios', true),
  ('CATALOGO_CARGAR_ARCHIVO',  'catalogo',      'Cargar el catálogo desde un archivo', false),
  ('USUARIO_ADMINISTRAR',      'usuarios',      'Administrar usuarios', false),
  ('CLAVE_RESTABLECER',        'usuarios',      'Restablecer contraseñas y PIN', true),
  ('PERMISO_CONFIGURAR',       'usuarios',      'Configurar permisos por rol', false),
  ('CONFIG_MODIFICAR',         'configuracion', 'Modificar la configuración del sistema', false);
 
-- Administrador: todos
INSERT INTO rol_permiso (rol_id, permiso) SELECT 1, codigo FROM permiso;
 
-- Supervisor
INSERT INTO rol_permiso (rol_id, permiso)
SELECT 2, codigo FROM permiso WHERE codigo IN (
  'VENTA_REGISTRAR','VENTA_SUSPENDER_CANCELAR','PAGO_REGISTRAR','CLIENTE_GESTIONAR',
  'FACTURA_REIMPRIMIR','FACTURA_ANULAR','CAJA_PROPIA','CAJA_CERRAR_OTRO',
  'CAJA_VER_CIERRES_OTROS','REPORTE_CONSULTAR','BITACORA_CONSULTAR','PRODUCTO_CONSULTAR');
 
-- Cajero
INSERT INTO rol_permiso (rol_id, permiso)
SELECT 3, codigo FROM permiso WHERE codigo IN (
  'VENTA_REGISTRAR','VENTA_SUSPENDER_CANCELAR','PAGO_REGISTRAR','CLIENTE_GESTIONAR',
  'FACTURA_REIMPRIMIR','CAJA_PROPIA','PRODUCTO_CONSULTAR');
 
-- ===== EP-01: usuarios =====
CREATE TABLE usuario (
  id                  bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  username            text NOT NULL,                      -- inmutable (HU-01.07)
  nombre_completo     text NOT NULL,
  rol_id              smallint NOT NULL REFERENCES rol(id),
  credencial_hash     text NOT NULL,                      -- Argon2id de contraseña o PIN
  credencial_temporal boolean NOT NULL DEFAULT true,      -- HU-01.15
  activo              boolean NOT NULL DEFAULT true,
  ultimo_acceso       timestamptz,
  creado_en           timestamptz NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX usuario_username_unico ON usuario (lower(username));
 
-- ===== HU-12.05: sucursal, impresora y caja =====
CREATE TABLE sucursal (            -- V1: una sola fila "Matriz"; deja listo EP-13
  id      bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  codigo  text UNIQUE NOT NULL,
  nombre  text UNIQUE NOT NULL,
  activo  boolean NOT NULL DEFAULT true
);
INSERT INTO sucursal (codigo, nombre) VALUES ('MATRIZ', 'Matriz');
 
CREATE TABLE impresora (
  id             bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  nombre         text NOT NULL,
  host           inet NOT NULL,
  puerto         int  NOT NULL DEFAULT 9100,
  ancho_mm       smallint NOT NULL CHECK (ancho_mm IN (58, 80)),
  copias_factura smallint NOT NULL DEFAULT 1,
  copias_cierre  smallint NOT NULL DEFAULT 1
);
 
CREATE TABLE caja (
  id                bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  sucursal_id       bigint NOT NULL REFERENCES sucursal(id),
  nombre            text NOT NULL,
  serie_fel         text,
  impresora_id      bigint REFERENCES impresora(id),
  token_equipo_hash bytea UNIQUE,                         -- vincula el equipo físico
  activo            boolean NOT NULL DEFAULT true,
  UNIQUE (sucursal_id, nombre)
);
 
-- ===== EP-01: sesiones =====
CREATE TABLE sesion (
  id           bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  token_hash   bytea UNIQUE NOT NULL,                     -- nunca el token en claro
  usuario_id   bigint NOT NULL REFERENCES usuario(id),
  caja_id      bigint REFERENCES caja(id),
  permisos     text[] NOT NULL,                           -- copia al iniciar (HU-01.07 crit. 4)
  iniciada_en  timestamptz NOT NULL DEFAULT now(),
  cerrada_en   timestamptz
);
CREATE INDEX sesion_usuario ON sesion (usuario_id) WHERE cerrada_en IS NULL;
 
-- ===== EP-11: bitácora inmodificable y encadenada =====
CREATE TABLE bitacora (
  id             bigint PRIMARY KEY,                      -- consecutivo sin huecos (lo asigna la función)
  ocurrido_en    timestamptz NOT NULL,                    -- hora del servidor (HU-11.02)
  usuario_id     bigint REFERENCES usuario(id),
  rol            text,
  caja_id        bigint REFERENCES caja(id),
  modulo         text NOT NULL,
  accion         text NOT NULL,
  exitoso        boolean NOT NULL,
  descripcion    text NOT NULL,
  entidad        text,
  entidad_id     bigint,
  cambios        jsonb,                                   -- {"precio": {"antes": "5.00", "despues": "5.50"}}
  hash_anterior  bytea NOT NULL,
  hash           bytea NOT NULL
);
CREATE INDEX bitacora_fecha   ON bitacora (ocurrido_en DESC);
CREATE INDEX bitacora_entidad ON bitacora (entidad, entidad_id);
CREATE INDEX bitacora_usuario ON bitacora (usuario_id, ocurrido_en DESC);
 
-- Hash de un registro: sha256(hash_anterior || datos). Lo usan registrar y verificar.
CREATE FUNCTION f_bitacora_hash(
  p_anterior bytea, p_id bigint, p_ts timestamptz, p_usuario_id bigint, p_rol text,
  p_caja_id bigint, p_modulo text, p_accion text, p_exitoso boolean, p_descripcion text,
  p_entidad text, p_entidad_id bigint, p_cambios jsonb
) RETURNS bytea
LANGUAGE sql STABLE AS $$
  SELECT public.digest(
    p_anterior || convert_to(concat_ws('|',
      p_id::text,
      extract(epoch FROM p_ts)::text,
      coalesce(p_usuario_id::text, ''),
      coalesce(p_rol, ''),
      coalesce(p_caja_id::text, ''),
      p_modulo,
      p_accion,
      p_exitoso::text,
      p_descripcion,
      coalesce(p_entidad, ''),
      coalesce(p_entidad_id::text, ''),
      coalesce(p_cambios::text, '')
    ), 'UTF8'),
    'sha256')
$$;
 
-- Única vía de escritura: pos_app solo puede EJECUTAR esta función.
CREATE FUNCTION registrar_bitacora(
  p_usuario_id  bigint,
  p_rol         text,
  p_caja_id     bigint,
  p_modulo      text,
  p_accion      text,
  p_exitoso     boolean,
  p_descripcion text,
  p_entidad     text  DEFAULT NULL,
  p_entidad_id  bigint DEFAULT NULL,
  p_cambios     jsonb DEFAULT NULL
) RETURNS bigint
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_id    bigint;
  v_prev  bytea;
  v_ts    timestamptz := clock_timestamp();
BEGIN
  -- Serializa las escrituras para mantener el orden de la cadena
  PERFORM pg_advisory_xact_lock(hashtext('bitacora'));
 
  SELECT b.id, b.hash INTO v_id, v_prev FROM bitacora b ORDER BY b.id DESC LIMIT 1;
  IF NOT FOUND THEN
    v_id   := 0;
    v_prev := decode(repeat('00', 32), 'hex');           -- bloque génesis
  END IF;
  v_id := v_id + 1;
 
  INSERT INTO bitacora (id, ocurrido_en, usuario_id, rol, caja_id, modulo, accion, exitoso,
                        descripcion, entidad, entidad_id, cambios, hash_anterior, hash)
  VALUES (v_id, v_ts, p_usuario_id, p_rol, p_caja_id, p_modulo, p_accion, p_exitoso,
          p_descripcion, p_entidad, p_entidad_id, p_cambios, v_prev,
          f_bitacora_hash(v_prev, v_id, v_ts, p_usuario_id, p_rol, p_caja_id, p_modulo,
                          p_accion, p_exitoso, p_descripcion, p_entidad, p_entidad_id, p_cambios));
  RETURN v_id;
END $$;
 
-- Verificación (HU-11.05 crit. 3): devuelve las filas con problemas; vacío = bitácora íntegra.
CREATE FUNCTION verificar_bitacora()
RETURNS TABLE (id bigint, motivo text)
LANGUAGE sql STABLE AS $$
  SELECT x.id,
         CASE
           WHEN x.id <> coalesce(x.prev_id, 0) + 1 THEN 'falta un registro anterior'
           WHEN x.hash_anterior <> coalesce(x.prev_hash, decode(repeat('00', 32), 'hex'))
                THEN 'cadena rota'
           WHEN x.hash <> f_bitacora_hash(x.hash_anterior, x.id, x.ocurrido_en, x.usuario_id,
                  x.rol, x.caja_id, x.modulo, x.accion, x.exitoso, x.descripcion,
                  x.entidad, x.entidad_id, x.cambios)
                THEN 'registro alterado'
         END
  FROM (
    SELECT b.*, lag(b.id)   OVER (ORDER BY b.id) AS prev_id,
                lag(b.hash) OVER (ORDER BY b.id) AS prev_hash
    FROM bitacora b
  ) x
  WHERE x.id <> coalesce(x.prev_id, 0) + 1
     OR x.hash_anterior <> coalesce(x.prev_hash, decode(repeat('00', 32), 'hex'))
     OR x.hash <> f_bitacora_hash(x.hash_anterior, x.id, x.ocurrido_en, x.usuario_id,
                  x.rol, x.caja_id, x.modulo, x.accion, x.exitoso, x.descripcion,
                  x.entidad, x.entidad_id, x.cambios)
$$;
 
-- Bloqueo de UPDATE, DELETE y TRUNCATE (HU-11.05 crit. 2)
CREATE FUNCTION bitacora_inmutable() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  RAISE EXCEPTION 'La bitácora es inmodificable: % no permitido', TG_OP
    USING ERRCODE = 'insufficient_privilege';
END $$;
 
CREATE TRIGGER bitacora_sin_cambios
  BEFORE UPDATE OR DELETE ON bitacora
  FOR EACH ROW EXECUTE FUNCTION bitacora_inmutable();
 
CREATE TRIGGER bitacora_sin_truncate
  BEFORE TRUNCATE ON bitacora
  FOR EACH STATEMENT EXECUTE FUNCTION bitacora_inmutable();
 
-- ===== Permisos de base de datos (Architecture.md §5.3) =====
-- Por si V1 definió privilegios por defecto, se limpian los de la bitácora.
REVOKE ALL ON bitacora FROM pos_app;
GRANT SELECT ON bitacora TO pos_app;
 
REVOKE ALL ON FUNCTION registrar_bitacora(bigint, text, bigint, text, text, boolean, text, text, bigint, jsonb) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION registrar_bitacora(bigint, text, bigint, text, text, boolean, text, text, bigint, jsonb) TO pos_app;
GRANT EXECUTE ON FUNCTION verificar_bitacora() TO pos_app;
 
-- V1 ya concede SELECT, INSERT, UPDATE por defecto sobre tablas nuevas (sin DELETE).
-- Estos GRANT solo lo dejan explícito. HU-01.10 (permisos por rol, Sprint 7) decidirá
-- cómo quitar un permiso de un rol sin DELETE.
GRANT SELECT, INSERT, UPDATE ON rol, permiso, rol_permiso, usuario, sucursal, impresora, caja, sesion TO pos_app;
 