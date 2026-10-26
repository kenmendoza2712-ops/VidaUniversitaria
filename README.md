# Vida Universitaria

Plataforma SaaS de reseñas de profesores y cursos, con analítica por carrera, facultad y periodo para las universidades.

Proyecto Final de **Bases de Datos II** (BTI23), Escuela de Tecnologías de la Información y Comunicación, Universidad Latina de Costa Rica.

## Integrantes

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

## Estructura del repositorio

```
VidaUniversitaria/
├── database/
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

## Requisitos

- SQL Server 2019 o superior (o SQL Server Express)
- SQL Server Management Studio (SSMS)
- Una cuenta con permisos de `sysadmin` en la instancia (necesaria para crear la base de datos y los logins)

## Instalación y ejecución

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

## Control de acceso

El API nunca se conecta con `sa` ni con permisos de `dbo`. Cada usuario tiene los permisos mínimos que necesita:

| Usuario SQL | Rol en la aplicación | Permisos |
|---|---|---|
| `app_admin` | Administración y coordinación | `EXECUTE` sobre todo el esquema `VidaU` |
| `app_user` | Estudiante | `EXECUTE` solo sobre 17 procedimientos (autenticación, catálogos, matrícula y reputación) |
| `app_readonly` | Coordinador de carrera | `EXECUTE` sobre 10 procedimientos de consulta. No puede leer `Usuario.Contrasena` |

Ningún usuario puede hacer `INSERT`, `UPDATE` ni `DELETE` directo sobre las tablas: toda escritura pasa por un stored procedure.

Las contraseñas de los logins son de ejemplo para el entorno de clase y deben cambiarse en cualquier otro entorno. La cadena de conexión del API irá en variables de entorno o en un archivo `.env` excluido del repositorio.

El API usa dos conexiones y elige según el rol del token: `app_user` para login, registro y acciones de estudiante, y `app_admin` para administración.

## Convenciones

- **Stored procedures:** `usp_<Entidad>_<Acción>` en la documentación, y `sp_<Entidad>_<Acción>` en el código, por ejemplo `sp_Resennia_Agregar`.
- **Restricciones:** prefijos `PK_`, `FK_`, `UQ_`, `CK_` y `DF_` seguidos del nombre de la tabla.
- **Códigos de error:** `50001` duplicado, `50002` no existe, `50003` tiene registros relacionados, `50023` reseña duplicada, `50030` credenciales incorrectas, `50040` suscripción traslapada.
- Los procedimientos usan `SET NOCOUNT ON` y `TRY...CATCH`.

## Avance del proyecto

| Revisión | Semana | Avance esperado | Estado |
|---|---|---|---|
| R1 | 3 | Propuesta aprobada, modelo ER, base de datos, usuarios y roles | Completada |
| R2 | 5 | 40 % de los procedimientos (incluye autenticación) y API ejecutando al menos uno | En presentación |
| R3 | 8 | 80 % de los procedimientos y transacciones explícitas | En presentación |
| R4 | 12 | Sistema completo y planes de ejecución documentados | Pendiente |
| Final | 15 | Todos los entregables, manual técnico y defensa oral | Pendiente |

Lista de verificación:

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

## Flujo de trabajo en equipo

```bash
git pull                                   # traer los cambios antes de empezar
git add .
git commit -m "Descripción corta del avance"
git push
```

Cada integrante hace commits con su propia cuenta, de modo que el historial refleje la contribución de cada uno.
