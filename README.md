# Vida Universitaria

Plataforma SaaS para consultar y publicar reseñas de cursos y profesores, con información académica organizada por universidad, sede, carrera y lección.

Proyecto final de **Bases de Datos II (BTI23)**, Universidad Latina de Costa Rica.

## Estado actual
- Base de datos `VidaUniversitariaDB` con el esquema `VidaU` y sus tablas.
- Procedimientos almacenados consolidados en `database/Procedimientos almacenados/Procedimientos Completos/PROCEDIMIENTOS COMPLETOS.sql`.
- Funciones, triggers y datos de demostración incluidos en la carpeta `database/`.
- API ASP.NET Core sobre .NET 10 en `database/API/Vidauniversitaria.Api/`.
- `GET /api/universidades` ejecuta `VidaU.sp_Universidad_Consultar` y devuelve JSON.
- La autenticación JWT y la autorización por roles están pendientes de implementación en la API.
=======
| Kendall Quesada |kenmendoza2712-ops || Maverick Garcia | MavGarciaB || Yorleni Rivera | Yorleni-06 || Diego Marchena | DiegoMarchena046 |

## Descripción

Los estudiantes consultan y publican reseñas anónimas de las lecciones que cursaron (un curso con un profesor y un horario concretos). Las universidades acceden a una sección analítica con promedios, rankings y evolución de las calificaciones.

**Modelo de negocio:** freemium. Los estudiantes usan la plataforma gratis; las universidades pagan una suscripción (plan mensual o anual) para acceder a la analítica.

## Arquitectura

```
Cliente (web / Postman)  →  API REST (.NET)  →  SQL Server
```

- **Base de datos:** concentra la lógica de negocio mediante stored procedures, funciones y triggers.
- **API REST (.NET):** recibe la petición HTTP, ejecuta el stored procedure correspondiente y devuelve el resultado en JSON. No contiene lógica de negocio.
- **Cliente de demostración:** aplicación web o colección de Postman.
>>>>>>> 06c4435a3df04d42cb426aff07f00fcb0a7118ce

## Estructura del repositorio

```text
NewRepo/
├── database/
<<<<<<< HEAD
│   ├── API/
│   │   └── Vidauniversitaria.Api/        Código fuente de la API
│   ├── Procedimientos almacenados/
│   │   ├── Procedimientos Completos/
│   │   │   └── PROCEDIMIENTOS COMPLETOS.sql
│   │   └── ...                            Archivos organizados por entidad
│   ├── ESQUEMA Y TABLAS.sql               Base de datos, esquema y tablas
│   ├── Control_Acceso.sql                 Logins, usuarios y permisos base
│   ├── Funciones.sql                      Funciones y procedimiento auxiliar
│   ├── Triggers.sql                       Triggers de reglas y auditoría
│   ├── Permisos_API.sql                   Permiso EXECUTE para el endpoint actual
│   └── DATOS SEMILLA Y PRUEBAS.sql        Datos de demostración y pruebas SQL
├── Diagramas/                              Diagramas del modelo
├── NewRepo.slnx                            Solución de Visual Studio
└── README.md
```

=======
│   ├── 01_esquema_tablas_y_seguridad.sql   Base de datos, esquema VidaU, 19 tablas, logins y usuarios
│   ├── 02_control_acceso.sql               Logins, usuarios y permisos base
│   ├── 03_todos_los_procedimientos.sql     85 procedimientos y 1 función de autenticación
│   ├── Funciones.sql                       2 funciones y 2 reportes
│   ├── Triggers.sql                        2 triggers
│   ├── 04_datos_semilla_y_pruebas.sql      Datos de ejemplo y pruebas del flujo
│   └── 05_permisos_por_procedimiento.sql   EXECUTE por procedimiento para cada rol
├── api/                                    API REST en .NET
└── README.md
```

## Modelo de datos

Todos los objetos viven en el esquema **`VidaU`** (no se usa `dbo`). El modelo tiene **19 tablas**:

| Grupo | Tablas |
|---|---|
| Catálogos | `Rol`, `Plan`, `Universidad`, `Carrera`, `Curso`, `Profesor` |
| Usuarios y auditoría | `Usuario`, `Estudiante`, `Bitacora` |
| Estructura académica | `Sede`, `Leccion` |
| Suscripciones | `Suscripcion` |
| Tablas puente (relaciones M:N) | `Universidad_Profesor`, `Sede_Carrera`, `Carrera_Curso`, `Carrera_Estudiante` |
| Participación estudiantil | `Matricula`, `Resennia`, `Evaluacion` |

Reglas principales del modelo:

- Un estudiante solo puede dejar **una reseña por lección** (`UNIQUE` sobre estudiante y lección).
- Las calificaciones van de **1 a 5**. La calificación general de una reseña es el promedio de sus `Evaluacion`.
- Una universidad no puede tener dos suscripciones activas con fechas traslapadas (trigger).
- Las contraseñas se guardan con `HASHBYTES`, nunca en texto plano.
- `Plan` es palabra reservada de SQL Server, por eso se escribe `VidaU.[Plan]` con corchetes.

## Objetos de la base de datos

| Tipo | Cantidad | Detalle |
|---|---|---|
| Tablas | 19 | Esquema `VidaU` |
| Procedimientos almacenados | 85 | CRUD por entidad, tablas puente, autenticación, matrícula, reseñas y consultas |
| Funciones | 3 | `fn_Auth_IntentosFallidos`, `fn_Suscripcion_Vigente`, `fn_Profesor_Reputacion` |
| Triggers | 2 | `trg_Suscripcion_ValidarTraslape` (regla de negocio), `trg_Resennia_AuditarEstado` (auditoría) |
| Transacciones explícitas | 63 bloques | Operaciones de escritura con `BEGIN TRANSACTION`, `COMMIT` y `ROLLBACK` |

>>>>>>> 06c4435a3df04d42cb426aff07f00fcb0a7118ce
## Requisitos

- SQL Server 2019 o superior (SQL Server Express sirve para desarrollo local).
- SQL Server Management Studio (SSMS).
- Visual Studio Community 2026 con la carga de trabajo de ASP.NET y web, y el SDK de .NET 10.
- Acceso al repositorio de GitHub.
- Una cuenta administrativa local de SQL Server para crear la base de datos y los logins durante la instalación.

## Preparar SQL Server

<<<<<<< HEAD
Conéctate a tu instancia local en SSMS usando una cuenta con permisos para crear bases de datos y logins. Ejecuta los siguientes archivos en este orden:

1. `database/ESQUEMA Y TABLAS.sql`: crea `VidaUniversitariaDB`, el esquema `VidaU` y las tablas. Se ejecuta una vez en una instancia limpia.
2. `database/Control_Acceso.sql`: crea los logins y usuarios de aplicación. Requiere la base creada.
3. `database/Procedimientos almacenados/Procedimientos Completos/PROCEDIMIENTOS COMPLETOS.sql`: crea el conjunto consolidado de procedimientos almacenados. **Ejecuta este archivo consolidado, no vuelvas a ejecutar además los archivos individuales de procedimientos.**
4. `database/Funciones.sql`: crea las funciones adicionales y el procedimiento auxiliar de vigencia de suscripción.
5. `database/Triggers.sql`: crea las reglas de traslape de suscripciones y la auditoría de cambios de estado de reseñas.
6. `database/Permisos_API.sql`: concede a `app_user` permiso para ejecutar el procedimiento que consume la API actual. Ejecútalo después de crear los procedimientos.
7. `database/DATOS SEMILLA Y PRUEBAS.sql`: carga datos ficticios y ejecuta pruebas. Córrelo una sola vez en una base de desarrollo vacía y después de instalar los procedimientos, funciones y triggers. Si falla a mitad, no lo repitas sin revisar la base; puede haber cargado parte de los datos.

Los archivos individuales de `database/Procedimientos almacenados/` se conservan para consulta y organización por entidad. Para una instalación desde cero, utiliza el script consolidado indicado en el paso 3.

La cuenta administrativa de SSMS ejecuta los scripts de instalación y semillas. La API se conecta con `app_user`, no con `sa` ni `dbo`.

## Configurar y ejecutar la API

1. Abre `NewRepo.slnx` desde la raíz del repositorio en Visual Studio.
2. En el Explorador de soluciones, haz clic derecho en `Vidauniversitaria.Api` y selecciona **Administrar secretos de usuario**.
3. En el archivo de secretos local, configura una cadena de conexión para tu propia instancia. Ejemplo:

   ```json
   {
     "ConnectionStrings": {
       "VidaU": "Server=SERVIDOR;Database=VidaUniversitariaDB;User Id=app_user;Password=CLAVE_LOCAL;Encrypt=True;TrustServerCertificate=True;"
     }
   }
   ```

   Reemplaza `SERVIDOR` por el nombre que muestra SSMS y `CLAVE_LOCAL` por la contraseña local de `app_user`. En instancias con nombre, representa la barra invertida como `\\` en JSON, por ejemplo `SERVIDOR\\SQLEXPRESS`.

4. Selecciona el perfil `https` y pulsa **F5**.
5. Prueba `https://localhost:7170/api/universidades` (si Visual Studio indica otro puerto, usa el que muestra allí).

La respuesta es un arreglo JSON. `[]` significa que el procedimiento se ejecutó, pero no hay universidades cargadas. Después de ejecutar los datos semilla, debe aparecer la universidad de ejemplo.

Los secretos de usuario son locales y no se guardan en Git. No agregues contraseñas personales ni archivos `secrets.json` al repositorio. Las credenciales que aparecen en los scripts SQL son solo para el entorno académico de demostración.
=======
Ejecutar **en este orden** los scripts de la carpeta `database/`, siempre con SSMS conectado a la instancia:

1. `01_esquema_tablas_y_seguridad.sql`: crea la base de datos `VidaUniversitariaDB`, el esquema `VidaU`, las 19 tablas, los logins y los usuarios.
2. `02_control_acceso.sql`: permisos base de los usuarios.
3. `03_todos_los_procedimientos.sql`: 85 procedimientos y la función de autenticación.
4. `Funciones.sql`: funciones y reportes de vigencia y reputación.
5. `Triggers.sql`: triggers de suscripciones y auditoría.
6. `04_datos_semilla_y_pruebas.sql`: datos de ejemplo y pruebas del flujo. Se ejecuta una sola vez.
7. `05_permisos_por_procedimiento.sql`: `EXECUTE` por procedimiento para `app_user` y `app_readonly`, y pruebas de permisos.

Cada script termina con una consulta de verificación. Si una verificación no coincide con lo esperado, detenerse y revisar antes de seguir.

Si se vuelve a crear la base de datos desde cero, hay que volver a correr los scripts 02 a 05: los usuarios y permisos de la base se eliminan con ella, aunque los logins del servidor se conservan.
>>>>>>> 06c4435a3df04d42cb426aff07f00fcb0a7118ce

## Control de acceso

El script `Control_Acceso.sql` define `app_admin`, `app_user` y `app_readonly`, con permisos separados. `Permisos_API.sql` concede a `app_user` solo el `EXECUTE` requerido por el endpoint de consulta de universidades. Los permisos adicionales deben agregarse de forma puntual cuando se implementen y protejan nuevos endpoints.

<<<<<<< HEAD
## Pruebas disponibles
=======
| Usuario SQL | Rol en la aplicación | Permisos |
|---|---|---|
| `app_admin` | Administración y coordinación | `EXECUTE` sobre todo el esquema `VidaU` |
| `app_user` | Estudiante | `EXECUTE` solo sobre 17 procedimientos (autenticación, catálogos, matrícula y reputación) |
| `app_readonly` | Coordinador de carrera | `EXECUTE` sobre 10 procedimientos de consulta. No puede leer `Usuario.Contrasena` |
>>>>>>> 06c4435a3df04d42cb426aff07f00fcb0a7118ce

`DATOS SEMILLA Y PRUEBAS.sql` valida varios flujos llamando a los procedimientos almacenados. Entre sus resultados esperados están el error `50030` para contraseña incorrecta, el error `50023` para una reseña duplicada y un promedio de `4.50` para tres evaluaciones. Esos errores son parte de pruebas esperadas, no indican por sí solos que la ejecución haya fallado.

<<<<<<< HEAD
La ruta `GET /api/universidades` es la comprobación de integración actual entre HTTP, la API y SQL Server.
=======
Las contraseñas de los logins son de ejemplo para el entorno de clase y deben cambiarse en cualquier otro entorno. La cadena de conexión del API irá en variables de entorno o en un archivo `.env` excluido del repositorio.

El API usa dos conexiones y elige según el rol del token: `app_user` para login, registro y acciones de estudiante, y `app_admin` para administración.
>>>>>>> 06c4435a3df04d42cb426aff07f00fcb0a7118ce

## Lineamientos y próximos entregables

<<<<<<< HEAD
El diseño mantiene la lógica de negocio en SQL Server. La API debe limitarse a autenticar y autorizar la petición, ejecutar el procedimiento correspondiente y serializar la respuesta. El trabajo pendiente para completar los entregables incluye, entre otros puntos:
=======
- **Stored procedures:** `usp_<Entidad>_<Acción>` en la documentación, y `sp_<Entidad>_<Acción>` en el código, por ejemplo `sp_Resennia_Agregar`.
- **Restricciones:** prefijos `PK_`, `FK_`, `UQ_`, `CK_` y `DF_` seguidos del nombre de la tabla.
- **Códigos de error:** `50001` duplicado, `50002` no existe, `50003` tiene registros relacionados, `50023` reseña duplicada, `50030` credenciales incorrectas, `50040` suscripción traslapada.
- Los procedimientos usan `SET NOCOUNT ON` y `TRY...CATCH`.
>>>>>>> 06c4435a3df04d42cb426aff07f00fcb0a7118ce

- Autenticación JWT con expiración máxima de ocho horas y autorización de endpoints por rol.
- Mapeo consistente de errores de SQL Server a códigos HTTP.
- Cliente de demostración, que puede ser una colección de Postman.
- Selección de tres consultas críticas y documentación de sus planes antes y después de optimizarlas.
- Manual técnico en PDF de al menos 20 páginas y presentación con demostración en vivo.

<<<<<<< HEAD
Cada nuevo script SQL debe llevar una cabecera que explique su propósito, requisitos previos, parámetros o datos que utiliza, orden de ejecución, efectos esperados y advertencias sobre si puede repetirse.
=======
| Revisión | Semana | Avance esperado | Estado |
|---|---|---|---|
| R1 | 3 | Propuesta aprobada, modelo ER, base de datos, usuarios y roles | Completada |
| R2 | 5 | 40 % de los procedimientos (incluye autenticación) y API ejecutando al menos uno | En presentación |
| R3 | 8 | 80 % de los procedimientos y transacciones explícitas | En presentación |
| R4 | 12 | Sistema completo y planes de ejecución documentados | Pendiente |
| Final | 15 | Todos los entregables, manual técnico y defensa oral | Pendiente |
>>>>>>> 06c4435a3df04d42cb426aff07f00fcb0a7118ce

## Trabajo en equipo

<<<<<<< HEAD
Antes de empezar, actualiza la copia local:
=======
- [x] Modelo entidad-relación y modelo relacional
- [x] Esquema de 19 tablas y control de acceso
- [x] Stored procedures de autenticación, usuarios y CRUD por entidad
- [x] Funciones (mínimo 2) y triggers (mínimo 1)
- [x] Transacciones explícitas (mínimo 3)
- [x] Permisos por procedimiento para cada rol
- [ ] Procedimientos de reseñas públicas (publicar, leer solo visibles)
- [ ] Reportes de analítica
- [ ] Optimización de consultas con planes de ejecución
- [ ] API REST con JWT y autorización por rol
- [ ] Manual técnico y presentación final
>>>>>>> 06c4435a3df04d42cb426aff07f00fcb0a7118ce

```bash
git pull
```

Después de revisar los cambios:

```bash
git add .
git commit -m "Describe el cambio realizado"
git push
```

Coordina quién modifica cada archivo para evitar conflictos. Cada integrante debe contribuir con su propia cuenta de GitHub.
