# Vida Universitaria

Plataforma SaaS de reseñas de profesores y cursos, con analítica por carrera, facultad y periodo para las universidades.

Proyecto Final de **Bases de Datos II** (BTI23), Escuela de Tecnologías de la Información y Comunicación, Universidad Latina de Costa Rica.

## Integrantes

| Kendall Quesada | @kenmendoza2712-ops || Maverick García | MavGarciaB || Yorleni Rivera | Yorleni-06 || Diego Marchena | DiegoMarchena06 |

## Descripción

Los estudiantes consultan y publican reseñas anónimas de las lecciones que cursaron (un curso con un profesor y un horario concretos). Las universidades acceden a una sección analítica con promedios, rankings y evolución de las calificaciones.

**Modelo de negocio:** freemium. Los estudiantes usan la plataforma gratis; las universidades pagan una suscripción (plan mensual o anual) para acceder a la analítica.

## Arquitectura

```
Cliente (Swagger UI / Postman)  →  API REST (.NET 10)  →  SQL Server
```

- **Base de datos:** concentra la lógica de negocio mediante stored procedures, funciones y triggers.
- **API REST (.NET 10):** recibe peticiones HTTP, ejecuta procedimientos almacenados mediante Entity Framework Core y devuelve los resultados en JSON. La lógica de acceso a datos está separada de los controladores y de `Program.cs`.
- **Documentación de la API:** OpenAPI y Swagger UI permiten consultar y probar los endpoints disponibles.
- **Cliente de demostración:** Swagger UI o una colección de Postman.

## Estructura del repositorio

```
VidaUniversitaria/
├── Diagramas/
├── database/
│   ├── API/
│   │   └── Vidauniversitaria.Api/
│   │       ├── Controllers/
│   │       │   └── UniversidadesController.cs
│   │       ├── Data/
│   │       │   └── VidaUniversitariaDbContext.cs
│   │       ├── DTOs/
│   │       │   └── UniversidadRespuestaDto.cs
│   │       ├── Services/
│   │       │   ├── IUniversidadService.cs
│   │       │   └── UniversidadService.cs
│   │       ├── Properties/
│   │       │   └── launchSettings.json
│   │       ├── Program.cs
│   │       └── Vidauniversitaria.Api.csproj
│   ├── Procedimientos almacenados/
│   ├── Control_Acceso.sql
│   ├── DATOS SEMILLA Y PRUEBAS.sql
│   ├── ESQUEMA Y TABLAS.sql
│   ├── Funciones.sql
│   ├── Permisos_API.sql
│   └── Triggers.sql
├── .gitattributes
├── .gitignore
├── NewRepo.slnx
└── README.md
```

Los archivos de configuración local del API no deben contener contraseñas reales ni cadenas de conexión sensibles.

## Modelo de datos

Todos los objetos viven en el esquema **`VidaU`** (no se usa `dbo`). El modelo tiene **19 tablas**:

| Grupo | Tablas |

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

| Tablas | 19 | Esquema `VidaU` |
| Procedimientos almacenados | 87 | 85 procedimientos en `Procedimientos almacenados/` y 2 reportes en `Funciones.sql` |
| Funciones | 3 | `fn_Auth_IntentosFallidos`, `fn_Suscripcion_Vigente`, `fn_Profesor_Reputacion` |
| Triggers | 2 | `trg_Suscripcion_ValidarTraslape` (regla de negocio), `trg_Resennia_AuditarEstado` (auditoría) |
| Transacciones explícitas | 63 bloques | Operaciones de escritura con `BEGIN TRANSACTION`, `COMMIT` y `ROLLBACK` |

## Requisitos

- SQL Server 2019 o superior (o SQL Server Express)
- SQL Server Management Studio (SSMS)
- Visual Studio Community con el SDK de .NET 10
- Una cuenta con permisos de `sysadmin` en la instancia (necesaria para crear la base de datos y los logins)

## Instalación y ejecución de la base de datos

Ejecutar los scripts de la carpeta `database/` en SSMS, conectado a la instancia de SQL Server y a la base de datos indicada por cada script:

1. `ESQUEMA Y TABLAS.sql`: crea la base de datos `VidaUniversitariaDB`, el esquema `VidaU` y las 19 tablas.
2. `Control_Acceso.sql`: configura logins, usuarios y permisos base.
3. Los scripts de `Procedimientos almacenados/`: crean los procedimientos del proyecto.
4. `Funciones.sql`: crea las funciones y los procedimientos de reportes.
5. `Triggers.sql`: crea los triggers de suscripciones y auditoría.
6. `DATOS SEMILLA Y PRUEBAS.sql`: inserta datos de ejemplo y prueba el flujo. Se ejecuta una sola vez sobre una base recién preparada.
7. `Permisos_API.sql`: configura permisos de ejecución por procedimiento y prueba los permisos correspondientes.

Si los archivos de procedimientos tienen dependencias entre sí, deben ejecutarse en el orden requerido por esas dependencias. Cada script debe revisarse y ejecutarse según la configuración de la instancia antes de continuar con el siguiente.

Si se vuelve a crear la base de datos desde cero, hay que volver a ejecutar los scripts de control de acceso, procedimientos, funciones, triggers, datos semilla y permisos. Los usuarios y permisos de base de datos se eliminan con ella, aunque los logins del servidor pueden conservarse.

## Ejecución del API

El proyecto del API está en:

`
database/API/Vidauniversitaria.Api/
`

La solución de Visual Studio está en la raíz del repositorio: `NewRepo.slnx`.

La cadena de conexión se obtiene mediante la configuración `ConnectionStrings:VidaU`. Para desarrollo local se guarda en **Secretos de usuario** de ASP.NET Core; no debe incluirse una contraseña real en GitHub.

En Visual Studio:

1. Abrir `NewRepo.slnx`.
2. Seleccionar el perfil de ejecución `https`.
3. Ejecutar el proyecto.
4. Swagger UI se abre automáticamente en el navegador. Si no se abre, se puede ingresar a `https://localhost:7170/swagger`.

El API incluye actualmente este endpoint:

| Método y ruta | Función |

| `GET /api/universidades` | Consulta todas las universidades mediante `VidaU.sp_Universidad_Consultar`. |
| `GET /api/universidades?idUniversidad=1` | Consulta la universidad cuyo identificador es `1` mediante el mismo procedimiento. |

El procedimiento permite recibir `NULL` para listar todas las universidades o un identificador para filtrar por una universidad específica. El resultado se transforma en un DTO y se devuelve como JSON.

## Control de acceso

La base de datos define usuarios con permisos mínimos según su función:

| Usuario SQL | Rol en la aplicación | Permisos |

| `app_admin` | Administración y coordinación | `EXECUTE` sobre los procedimientos administrativos autorizados |
| `app_user` | Estudiante | `EXECUTE` solo sobre procedimientos autorizados para estudiantes |
| `app_readonly` | Coordinador de carrera | `EXECUTE` sobre procedimientos de consulta. No puede leer `Usuario.Contrasena` |

Ningún usuario de aplicación debe hacer `INSERT`, `UPDATE` ni `DELETE` directo sobre las tablas: las escrituras pasan por procedimientos almacenados.

**Estado actual de la API:** utiliza la cadena de conexión `VidaU` configurada localmente mediante Secretos de usuario. El endpoint de consulta de universidades ejecuta un procedimiento almacenado. La API todavía no selecciona una conexión según el rol de un token, ni implementa JWT o autorización por roles.

Las contraseñas de los logins son de ejemplo para el entorno de clase y deben cambiarse en cualquier otro entorno. No se deben subir contraseñas ni cadenas de conexión con credenciales al repositorio.

## Convenciones

- **Stored procedures:** `usp_<Entidad>_<Acción>` en la documentación y `sp_<Entidad>_<Acción>` en el código, por ejemplo `sp_Resennia_Agregar`.
- **Restricciones:** prefijos `PK_`, `FK_`, `UQ_`, `CK_` y `DF_` seguidos del nombre de la tabla.
- **Códigos de error:** `50001` duplicado, `50002` no existe, `50003` tiene registros relacionados, `50023` reseña duplicada, `50030` credenciales incorrectas, `50040` suscripción traslapada.
- Los procedimientos usan `SET NOCOUNT ON` y `TRY...CATCH`.

## Avance del proyecto

| Revisión | Semana | Avance esperado | Estado |
|---|---:|---|---|
| R1 | 3 | Propuesta aprobada, modelo ER, base de datos, usuarios y roles | Completada |
| R2 | 5 | 40 % de los procedimientos (incluye autenticación) y API ejecutando al menos uno | Completada |
| R3 | 8 | 80 % de los procedimientos y transacciones explícitas | Completada |
| R4 | 12 | Sistema completo y planes de ejecución documentados | Pendiente |
| Final | 15 | Todos los entregables, manual técnico y defensa oral | Pendiente |

Lista de verificación:

- [x] Modelo entidad-relación y modelo relacional
- [x] Esquema de 19 tablas y control de acceso
- [x] Stored procedures de autenticación, usuarios y CRUD por entidad
- [x] Al menos el 40 % de los procedimientos almacenados implementados, incluidos los de autenticación (R2)
- [x] API REST ejecuta al menos un procedimiento almacenado (R2)
- [x] Al menos el 80 % de los procedimientos almacenados implementados (R3)
- [x] Transacciones explícitas implementadas (63 bloques)
- [x] Funciones (mínimo 2) y triggers (mínimo 1)
- [x] Permisos por procedimiento para cada rol
- [ ] Procedimientos de reseñas públicas (publicar, leer solo visibles)
- [ ] Reportes de analítica
- [ ] Optimización de consultas con planes de ejecución
- [ ] API REST con JWT y autorización por rol
- [ ] Manual técnico y presentación final

## Flujo de trabajo en equipo

```bash
git pull
git add .
git commit -m "Descripción corta del avance"
git push
```

Cada integrante hace commits con su propia cuenta, de modo que el historial refleje la contribución de cada uno.
