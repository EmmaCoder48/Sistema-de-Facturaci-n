# Sistema POS Supermercado (FEL Guatemala)

Código del sistema descrito en [`../claude/Architecture.md`](../claude/Architecture.md). Este es el entorno del **Sprint 0**: el esqueleto ya compila, se conecta a PostgreSQL y tiene pruebas automáticas, pero todavía no implementa historias de usuario.

## Requisitos

| Herramienta | Versión | Para qué |
|-------------|---------|----------|
| JDK | 21 o superior | Backend (se compila con `release 21`) |
| Node.js | 24 o superior | Frontend |
| Docker Desktop | reciente | PostgreSQL local y pruebas con Testcontainers |

No hace falta instalar Maven: el proyecto trae el Maven Wrapper (`mvnw`).

## Puesta en marcha

1. Copiar las variables de entorno (opcional; sin `.env` se usan los valores de desarrollo):

   ```bash
   cp .env.example .env
   ```

2. Levantar PostgreSQL 16:

   ```bash
   docker compose up -d
   ```

   La primera vez, `docker/postgres/init/01-roles.sh` crea la base `pos_db` y los roles `pos_owner` y `pos_app`.

   El contenedor queda en el puerto **5433** (no en el 5432) para no chocar con un PostgreSQL instalado directamente en Windows. Para usar otro puerto, cambiar `POS_DB_PORT` en `.env`. Si se cambian las contraseñas después de crear el volumen, hay que recrearlo con `docker compose down -v` (esto **borra** los datos de desarrollo).

3. Arrancar el backend (aplica las migraciones Flyway y queda en `http://localhost:8080`):

   ```bash
   cd backend && ./mvnw spring-boot:run
   ```

   En Windows (PowerShell o CMD) se usa `mvnw.cmd spring-boot:run`.

4. Arrancar el frontend (queda en `http://localhost:5173`):

   ```bash
   cd frontend && npm install && npm run dev
   ```

5. Abrir `http://localhost:5173`. La pantalla **Estado del entorno** muestra la versión del backend, la versión de PostgreSQL, el modo del certificador FEL y la hora del servidor.

## Pruebas

```bash
cd backend && ./mvnw verify
```

```bash
cd frontend && npm run lint && npm test && npm run build
```

| Prueba | Qué verifica |
|--------|--------------|
| `ArquitecturaTest` | Reglas de módulos y capas con ArchUnit: `dominio` no depende de `api`, `infraestructura` ni Spring; `impuestos` es cálculo puro; un módulo no usa la `api` ni la `infraestructura` de otro. |
| `SistemaIntegracionTest` | Contra PostgreSQL real (Testcontainers): migraciones aplicadas, extensiones `pg_trgm`/`unaccent`/`pgcrypto`, búsqueda sin tildes, privilegios de `pos_app` sin `DELETE`, `/api/sistema/info` público y demás rutas con 401. **Necesita Docker en ejecución.** |
| `CertificadorFelSimuladoTest` | El simulador FEL no duplica facturas con el mismo identificador, y simula rechazo y falta de conexión. |
| `atajos.test.ts` | Atajos de teclado de la caja sin teclas repetidas y con las acciones de HU-06.17. |

El workflow `.github/workflows/ci.yml` corre todo lo anterior en cada push y pull request cuando el repositorio esté en GitHub.

## Estructura

```
Sistema/
├── docker-compose.yml          PostgreSQL 16 para desarrollo
├── docker/postgres/init/       creación de la base de datos y los roles
├── .env.example                variables de entorno
├── .github/workflows/ci.yml    integración continua
├── backend/                    Java 21 + Spring Boot 4.1
│   └── src/main/java/gt/supermercado/pos/
│       ├── compartido/         errores de API, estado del sistema
│       ├── seguridad/          EP-01   (SeguridadConfig provisional)
│       ├── catalogo/           EP-03
│       ├── impuestos/          EP-04   (cálculo puro, sin BD)
│       ├── clientes/           EP-05
│       ├── ventas/             EP-06
│       ├── pagos/              EP-07
│       ├── facturacion/        EP-08   (puerto CertificadorFel + simulador)
│       ├── caja/               EP-09
│       ├── reportes/           EP-10
│       ├── bitacora/           EP-11
│       ├── configuracion/      EP-12
│       └── impresion/          tickets ESC/POS
│           (cada módulo: api/ aplicacion/ dominio/ infraestructura/)
└── frontend/                   React 19 + TypeScript + Vite
    └── src/
        ├── api/                cliente HTTP tipado
        ├── atajos/             mapa central de atajos de teclado
        ├── componentes/        componentes compartidos
        └── modulos/            una carpeta por pantalla o módulo
```

## Convenciones del equipo

- **Migraciones:** una o más por sprint, con el nombre `V{n}__{descripcion}.sql` en `backend/src/main/resources/db/migration`. Una migración ya aplicada nunca se edita; los cambios van en una nueva. Orden previsto: `V2__seguridad`, `V3__catalogo`, `V4__caja`, ...
- **Perfiles de Spring:** `dev` (por defecto, usa docker compose), `test` (Testcontainers) y `prod` (servidor del supermercado, todo por variables de entorno).
- **Certificador FEL:** `pos.fel.modo=simulado` mientras no se contrate el certificador. El escenario `pos.fel.simulador.escenario` (`ACEPTAR`, `RECHAZAR`, `SIN_CONEXION`) permite probar rechazos y contingencia.
- **Dinero:** siempre `BigDecimal` en Java y `NUMERIC` en PostgreSQL. El frontend no calcula montos, solo muestra los que devuelve el backend.
- **Ramas:** `main` (lo entregado), `develop` (integración del sprint) y `feature/HU-xx.yy-descripcion` por historia.
- **Fecha y hora:** siempre las del servidor de base de datos (`now()`), nunca las de la caja.

## Definición de "Hecho"

Una historia está terminada cuando:

1. Cumple todos sus criterios de aceptación y se demostró en la revisión del sprint.
2. Tiene pruebas automáticas y el CI está en verde (`./mvnw verify` y las pruebas del frontend).
3. Los cambios de base de datos están en una migración Flyway nueva.
4. Los permisos se validan en el backend, no solo en la interfaz.
5. Las acciones sensibles quedan registradas en la bitácora (EP-11).
6. Otro integrante del equipo revisó el código.

## Pendiente para el Sprint 1

- Reemplazar `SeguridadConfig` provisional por el inicio de sesión con contraseña o PIN y la tabla `sesion` (HU-01.01, 01.02).
- Migración `V2__seguridad.sql` con roles, permisos y la matriz inicial de permisos.
- Infraestructura de la bitácora encadenada (HU-11.01, 11.02, 11.05).
