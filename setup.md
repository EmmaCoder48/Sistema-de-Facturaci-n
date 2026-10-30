# Instalación en una máquina nueva (Windows)

Guía para dejar funcionando el sistema POS en cualquier computadora con Windows, a partir del `.zip` de la carpeta `Sistema` y una base de datos PostgreSQL local.

Todos los comandos son de **PowerShell**. Los que dicen **(como administrador)** se ejecutan en una ventana abierta con clic derecho → *Ejecutar como administrador*.

---

## Resumen de lo que hay que instalar

| # | Programa | Versión | ¿Obligatorio? | Comando de instalación | Descarga manual |
|---|----------|---------|---------------|------------------------|-----------------|
| 1 | Java JDK (Eclipse Temurin) | 21 | Sí | `winget install --id EclipseAdoptium.Temurin.21.JDK --exact` | https://adoptium.net/temurin/releases/?version=21&os=windows |
| 2 | Node.js (LTS) | 24 o superior | Sí | `winget install --id OpenJS.NodeJS.LTS --exact` | https://nodejs.org/en/download |
| 3A | WSL 2 + Docker Desktop | reciente | Sí, si usa la **opción A** de base de datos | `wsl --install` y `winget install --id Docker.DockerDesktop --exact` | https://learn.microsoft.com/windows/wsl/install · https://docs.docker.com/desktop/setup/install/windows-install/ |
| 3B | PostgreSQL | 16 (o superior) | Sí, si usa la **opción B** de base de datos | `winget install --id PostgreSQL.PostgreSQL.16 --exact --interactive` | https://www.enterprisedb.com/downloads/postgres-postgresql-downloads |
| 4 | Git | reciente | Opcional (para trabajar con el repositorio) | `winget install --id Git.Git --exact` | https://git-scm.com/downloads/win |

**No hace falta instalar** Maven (el proyecto trae el Maven Wrapper `mvnw.cmd`) ni Vite, React o TypeScript (se instalan con `npm install`).

**Base de datos — elija una opción:**
- **Opción A, Docker (recomendada):** la base de datos corre en un contenedor, igual en todas las máquinas del equipo, y es la que usan las pruebas automáticas. Además, las pruebas de integración del backend (`mvnw verify`) **necesitan Docker** aunque use la opción B.
- **Opción B, PostgreSQL instalado en Windows:** no necesita Docker ni virtualización. Útil en equipos con poca memoria o sin virtualización, y parecida a cómo quedará en el servidor del supermercado.

---

## 0. Requisitos de la máquina

| Requisito | Mínimo |
|-----------|--------|
| Sistema operativo | Windows 10 22H2 o Windows 11, de 64 bits |
| Memoria RAM | 8 GB (16 GB recomendado si usa Docker) |
| Disco libre | 10 GB |
| Virtualización | Activada en la BIOS (solo para la opción A, Docker) |
| Internet | Necesario la **primera vez**: se descargan Maven, las dependencias de Java, los paquetes de npm y la imagen de PostgreSQL |
| Puertos libres | `5433` (PostgreSQL en Docker) o `5432` (PostgreSQL de Windows), `8080` (backend) y `5173` (frontend) |

Comprobar que `winget` está disponible (viene con Windows 10/11 actualizados):

```powershell
winget --version
```

Si no aparece, instalar o actualizar **App Installer** desde Microsoft Store: https://apps.microsoft.com/detail/9NBLGGH4NNS1

Comprobar si la virtualización está activada (opción A):

```powershell
(Get-CimInstance Win32_Processor).VirtualizationFirmwareEnabled
```

Si muestra `False`, hay que activarla en la BIOS/UEFI (opción "Intel VT-x", "AMD-V" o "SVM").

---

## 1. Java JDK 21 (Eclipse Temurin)

Necesario para compilar y ejecutar el backend (Spring Boot).

```powershell
winget install --id EclipseAdoptium.Temurin.21.JDK --exact
```

Descarga manual: https://adoptium.net/temurin/releases/?version=21&os=windows (elegir el instalador `.msi` x64 y marcar las opciones *Add to PATH* y *Set JAVA_HOME*).

Cerrar y volver a abrir PowerShell, y comprobar:

```powershell
java -version
```

Debe mostrar `21` o una versión superior.

---

## 2. Node.js (LTS)

Necesario para el frontend (React + Vite). Trae `npm`.

```powershell
winget install --id OpenJS.NodeJS.LTS --exact
```

Descarga manual: https://nodejs.org/en/download (instalador *Windows Installer (.msi)* de la versión LTS).

Cerrar y volver a abrir PowerShell, y comprobar:

```powershell
node -v
```

```powershell
npm.cmd -v
```

> En Windows PowerShell 5.1, escribir solo `npm` puede fallar con *"la ejecución de scripts está deshabilitada en este sistema"*. Hay dos soluciones: usar siempre `npm.cmd` (como en esta guía) o permitir scripts locales para su usuario con:
>
> ```powershell
> Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
> ```

---

## 3. Base de datos

### Opción A — Docker Desktop (recomendada)

**3A.1. Instalar WSL 2 (como administrador)** y reiniciar la computadora:

```powershell
wsl --install
```

Guía oficial: https://learn.microsoft.com/windows/wsl/install

**3A.2. Instalar Docker Desktop (como administrador)** y reiniciar otra vez si lo pide:

```powershell
winget install --id Docker.DockerDesktop --exact
```

Descarga manual: https://docs.docker.com/desktop/setup/install/windows-install/

**3A.3. Abrir Docker Desktop** una vez (aceptar los términos de uso) y esperar a que diga *Engine running*. Comprobar:

```powershell
docker --version
```

```powershell
docker compose version
```

```powershell
docker ps
```

`docker ps` no debe mostrar ningún error. Si dice *failed to connect to the docker API*, Docker Desktop todavía no terminó de arrancar.

### Opción B — PostgreSQL instalado en Windows

**3B.1. Instalar PostgreSQL 16 (como administrador).** El parámetro `--interactive` abre el asistente para que usted elija la contraseña del usuario `postgres`; anótela.

```powershell
winget install --id PostgreSQL.PostgreSQL.16 --exact --interactive
```

Descarga manual: https://www.enterprisedb.com/downloads/postgres-postgresql-downloads (Windows x86-64, versión 16).

En el asistente: dejar el puerto **5432**, instalar los componentes *PostgreSQL Server* y *Command Line Tools*. No hace falta *Stack Builder*.

Comprobar que el servicio está corriendo:

```powershell
Get-Service postgresql*
```

Debe aparecer con estado `Running`.

> También sirve una versión más nueva (17 o 18) si ya está instalada; el sistema solo necesita las extensiones `pg_trgm`, `unaccent` y `pgcrypto`, que vienen incluidas.

---

## 4. Descomprimir el proyecto

Copiar `Sistema.zip` a la máquina y descomprimirlo, por ejemplo en `C:\POS`:

```powershell
Expand-Archive -Path "$HOME\Downloads\Sistema.zip" -DestinationPath C:\POS
```

```powershell
Set-Location C:\POS\Sistema
```

Si Windows marca los archivos como descargados de internet y bloquea algún script, desbloquearlos:

```powershell
Get-ChildItem -Recurse | Unblock-File
```

> **Cómo generar el `.zip` correctamente** (en la máquina de origen, dentro de `Sistema`): use `git archive`, que incluye solo los archivos del repositorio y deja fuera `node_modules`, `target` y `.env`.
>
> ```powershell
> git archive --format=zip --prefix=Sistema/ -o "$HOME\Desktop\Sistema.zip" HEAD
> ```
>
> Si se comprime la carpeta a mano, **borrar antes** `frontend\node_modules`, `frontend\dist` y `backend\target`: ocupan cientos de MB y se regeneran solos.

---

## 5. Crear la base de datos local

### Opción A — con Docker

Desde `C:\POS\Sistema`, con Docker Desktop abierto:

```powershell
Copy-Item .env.example .env
```

```powershell
docker compose up -d
```

La primera vez descarga la imagen `postgres:16-alpine` y crea la base `pos_db` con los roles `pos_owner` y `pos_app`. Queda en el puerto **5433**. Comprobar que está sana:

```powershell
docker compose ps
```

La columna `STATUS` debe decir `healthy`.

### Opción B — con PostgreSQL de Windows

Desde `C:\POS\Sistema`, ejecutar el script de creación con el usuario `postgres` (pedirá la contraseña elegida en el paso 3B.1):

```powershell
& "C:\Program Files\PostgreSQL\16\bin\psql.exe" -U postgres -f scripts\crear-base-local.sql
```

Debe terminar con *Base de datos pos_db creada con los roles pos_owner y pos_app*. Si su versión es otra, cambie `16` en la ruta por `17` o `18`.

Como PostgreSQL de Windows usa el puerto **5432** (y no el 5433 de Docker), indique el puerto al backend. Para que quede guardado para su usuario:

```powershell
[Environment]::SetEnvironmentVariable("POS_DB_PORT", "5432", "User")
```

Cierre y vuelva a abrir PowerShell para que tome la variable.

> El archivo `.env` **solo lo lee Docker Compose**. El backend toma la configuración de las variables de entorno de Windows, con los valores de desarrollo por defecto de `backend\src\main\resources\application-dev.yml`.

---

## 6. Ejecutar el backend

En una ventana de PowerShell, desde `C:\POS\Sistema`:

```powershell
Set-Location backend
```

```powershell
.\mvnw.cmd spring-boot:run
```

La primera vez descarga Maven y las dependencias (unos minutos). Está listo cuando aparece `Started PosBackendApplication`. Al arrancar aplica las migraciones de la base de datos automáticamente.

Comprobar desde **otra** ventana de PowerShell:

```powershell
Invoke-RestMethod http://localhost:8080/api/sistema/info
```

Debe mostrar la versión, `modoFel : simulado`, la versión de PostgreSQL y la hora del servidor.

---

## 7. Ejecutar el frontend

En otra ventana de PowerShell, desde `C:\POS\Sistema`:

```powershell
Set-Location frontend
```

```powershell
npm.cmd install
```

```powershell
npm.cmd run dev
```

Abrir en el navegador:

```powershell
Start-Process http://localhost:5173
```

La pantalla **Estado del entorno** debe mostrar *Backend: Conectado*, la versión de PostgreSQL y la hora del servidor.

---

## 8. Verificar con las pruebas automáticas (opcional)

Backend (necesita **Docker en ejecución**, también con la opción B, porque las pruebas crean su propio PostgreSQL temporal):

```powershell
Set-Location C:\POS\Sistema\backend; .\mvnw.cmd verify
```

Debe terminar con `Tests run: 13, Failures: 0` y `BUILD SUCCESS`.

Frontend:

```powershell
Set-Location C:\POS\Sistema\frontend; npm.cmd run lint; npm.cmd test; npm.cmd run build
```

---

## Uso diario

| Acción | Comando (desde `C:\POS\Sistema`) |
|--------|----------------------------------|
| Encender la base de datos (opción A) | `docker compose up -d` |
| Apagar la base de datos (opción A) | `docker compose stop` |
| Encender el backend | `Set-Location backend; .\mvnw.cmd spring-boot:run` |
| Encender el frontend | `Set-Location frontend; npm.cmd run dev` |
| Detener backend o frontend | `Ctrl + C` en su ventana |

Con la opción B, el servicio de PostgreSQL arranca solo con Windows.

---

## Solución de problemas

| Síntoma | Causa probable | Solución |
|---------|----------------|----------|
| `java` o `node` *no se reconoce como nombre de un cmdlet* | PowerShell se abrió antes de instalar | Cerrar y abrir PowerShell de nuevo |
| `mvnw.cmd` dice *JAVA_HOME not found* | El instalador de Java no definió `JAVA_HOME` | Ejecutar el comando de abajo y reabrir PowerShell |
| `npm` dice *la ejecución de scripts está deshabilitada* | Política de ejecución de PowerShell | Usar `npm.cmd` o `Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned` |
| *failed to connect to the docker API* | Docker Desktop no está abierto o sigue arrancando | Abrir Docker Desktop y esperar *Engine running* |
| *la autentificación password falló para el usuario «pos_owner»* | El backend llegó a otro PostgreSQL (por ejemplo, uno de Windows en el 5432 cuando se esperaba Docker en el 5433), o las contraseñas no coinciden | Revisar `POS_DB_PORT` y los puertos con el comando de abajo |
| *Port 8080 was already in use* o Vite usa otro puerto | Otro programa ocupa el puerto | Ver qué proceso lo usa con el comando de abajo y cerrarlo |
| `docker compose up` no aplica una contraseña nueva | La base se creó antes con otra contraseña | `docker compose down -v` (**borra** los datos de desarrollo) y `docker compose up -d` |
| `psql` *el rol «pos_owner» ya existe* (opción B) | El script ya se ejecutó antes | No hace falta volver a ejecutarlo |

Definir `JAVA_HOME` con el JDK 21 instalado por Temurin:

```powershell
$jdk = (Get-ChildItem "C:\Program Files\Eclipse Adoptium" -Directory -Filter "jdk-21*" | Select-Object -First 1).FullName; [Environment]::SetEnvironmentVariable("JAVA_HOME", $jdk, "User"); $jdk
```

Ver qué programa usa cada puerto del sistema:

```powershell
Get-NetTCPConnection -LocalPort 5432,5433,8080,5173 -State Listen -ErrorAction SilentlyContinue | Select-Object LocalAddress, LocalPort, @{n='Proceso';e={(Get-Process -Id $_.OwningProcess).ProcessName}}
```
