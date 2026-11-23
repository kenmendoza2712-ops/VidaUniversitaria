# Vida Universitaria

Plataforma SaaS de reseñas de profesores y cursos, con analítica para las universidades.

Proyecto Final de **Bases de Datos II** (BTI23), Escuela de Tecnologías de la Información y Comunicación, Universidad Latina de Costa Rica.

## Integrantes

| Kendall Quesada | @kenmendoza2712-ops || Maverick García | MavGarciaB || Yorleni Rivera | Yorleni-06 || Diego Marchena | DiegoMarchena06 

## Descripción

Los estudiantes consultan y publican reseñas anónimas de las lecciones que cursaron, asociadas a un curso, un profesor y un horario. Las universidades pueden consultar información analítica sobre las calificaciones.

**Modelo de negocio:** freemium. Los estudiantes usan la plataforma gratis; las universidades pagan una suscripción, mensual o anual, para acceder a la analítica.

## Arquitectura

```
Cliente (Swagger UI / Postman)  →  API REST (.NET 10)  →  SQL Server
```

- **Base de datos:** concentra la lógica de negocio mediante procedimientos almacenados, funciones y triggers.
- **API REST (.NET 10):** recibe peticiones HTTP, ejecuta procedimientos almacenados mediante Entity Framework Core y devuelve los resultados en JSON. Los controladores delegan el acceso a datos en servicios; `Program.cs` registra las dependencias y configura la aplicación.
- **Modelos EF Core:** las entidades y `VidaUniversitariaScaffoldContext` se generaron desde el esquema `VidaU` mediante Scaffold. Las cuatro tablas puente están representadas como relaciones muchos a muchos en el contexto, por lo que no tienen una clase de entidad independiente.
- **Acceso a datos:** `UniversidadService` utiliza el contexto generado para ejecutar `VidaU.sp_Universidad_Consultar`. Las operaciones de negocio se realizan mediante procedimientos almacenados; el API no modifica directamente las tablas.
- **Documentación de la API:** OpenAPI y Swagger UI permiten consultar y probar los endpoints disponibles.
- **Cliente de demostración:** Swagger UI o Postman.

## Estructura del repositorio

```
VidaUniversitaria/
├── Diagramas/
├── database/
│   ├── API/
│   │   ├── Permisos_API.sql
│   │   └── Vidauniversitaria.Api/
│   │       ├── Controllers/
│   │       │   └── UniversidadesController.cs
│   │       ├── Data/
│   │       │   └── Scaffold/
│   │       │       └── VidaUniversitariaScaffoldContext.cs
│   │       ├── DTOs/
│   │       │   └── UniversidadRespuestaDto.cs
│   │       ├── Models/
│   │       │   └── Scaffold/ (15 clases de entidad)
│   │       ├── Services/
│   │       │   ├── IUniversidadService.cs
│   │       │   └── UniversidadService.cs
│   │       ├── Properties/
│   │       │   └── launchSettings.json
│   │       ├── Program.cs
│   │       ├── Vidauniversitaria.Api.csproj
│   │       └── Vidauniversitaria.Api.http
│   ├── Control y Acceso/
│   │   └── Control_Acceso.sql
│   ├── Funciones y Triggers/
│   │   ├── Funciones.sql
│   │   └── Triggers.sql
│   ├── Procedimientos almacenados/
│   │   ├── 20_Autenticacion/
│   │   ├── Procedimientos Completos/
│   │   │   └── PROCEDIMIENTOS COMPLETOS.sql
│   │   ├── Tablas de cuarto nivel/
│   │   ├── Tablas de primer nivel/
│   │   ├── Tablas de segundo nivel/
│   │   ├── Tablas de tercer nivel/
│   │   ├── Tablas puente/
│   │   └── Tablas sin dependencias/
│   ├── Pruebas/
│   │   └── DATOS SEMILLA Y PRUEBAS.sql
│   └── Tablas/
│       ├── ESQUEMA Y TABLAS.sql
│       └── Tabla_*.sql
├── .gitattributes
├── .gitignore
├── NewRepo.slnx
└── README.md
```

Los archivos de configuración local del API no deben contener contraseñas reales ni cadenas de conexión sensibles. La conexión de desarrollo se configura mediante **Secretos de usuario** de ASP.NET Core.

## Modelo de datos

Todos los objetos viven en el esquema **`VidaU`**; no se utiliza `dbo`. El modelo tiene **19 tablas**:

| Grupo | Tablas |

| Catálogos | `Rol`, `Plan`, `Universidad`, `Carrera`, `Curso`, `Profesor` |
| Usuarios y auditoría | `Usuario`, `Estudiante`, `Bitacora` |
| Estructura académica | `Sede`, `Leccion` |
| Suscripciones | `Suscripcion` |
| Tablas puente (relaciones M:N) | `Universidad_Profesor`, `Sede_Carrera`, `Carrera_Curso`, `Carrera_Estudiante` |
| Participación estudiantil | `Matricula`, `Resennia`, `Evaluacion` |

El proceso de Scaffold generó **15 clases de entidad**. Las cuatro tablas puente se configuran como relaciones muchos a muchos en `VidaUniversitariaScaffoldContext`.

Reglas principales del modelo:

- Un estudiante solo puede dejar **una reseña por lección** mediante una restricción `UNIQUE` sobre estudiante y lección.
- Las calificaciones van de **1 a 5**. La calificación general de una reseña se obtiene del promedio de sus `Evaluacion`.
- Una universidad no puede tener dos suscripciones activas con fechas traslapadas; esta regla se valida mediante un trigger.
- Las contraseñas se guardan con `HASHBYTES`, nunca en texto plano.
- `Plan` es palabra reservada de SQL Server, por eso se escribe `VidaU.[Plan]` con corchetes.

## Objetos de la base de datos

| Tipo | Cantidad | Detalle |
|---|---:|---|
| Tablas | 19 | Esquema `VidaU` |
| Procedimientos almacenados | 87 | 85 procedimientos por entidad y autenticación, más 2 reportes en `Funciones.sql` |
| Funciones | 3 | `fn_Auth_IntentosFallidos`, `fn_Suscripcion_Vigente`, `fn_Profesor_Reputacion` |
| Triggers | 2 | `trg_Suscripcion_ValidarTraslape` y `trg_Resennia_AuditarEstado` |
| Transacciones explícitas | 63 bloques | Operaciones de escritura con `BEGIN TRANSACTION`, `COMMIT` y `ROLLBACK` |

## Requisitos

- SQL Server 2019 o superior (o SQL Server Express)
- SQL Server Management Studio (SSMS)
- Visual Studio Community con el SDK de .NET 10
- Paquetes NuGet de SQL Server y Entity Framework Core 10
- Una cuenta con permisos de `sysadmin` en la instancia para crear la base de datos y los logins

## Instalación y ejecución de la base de datos

Ejecutar los scripts en SSMS, conectado a la instancia de SQL Server. Para una base nueva, seguir el orden de dependencias:

1. `database/Tablas/ESQUEMA Y TABLAS.sql`: crea `VidaUniversitariaDB`, el esquema `VidaU` y las 19 tablas.
2. `database/Control y Acceso/Control_Acceso.sql`: configura los logins, usuarios y permisos base.
3. Los scripts individuales de `database/Procedimientos almacenados/`: crean los procedimientos. Ejecutarlos según sus dependencias.
4. `database/Funciones y Triggers/Funciones.sql`: crea las funciones y los procedimientos de reportes.
5. `database/Funciones y Triggers/Triggers.sql`: crea los triggers de suscripciones y auditoría.
6. `database/Pruebas/DATOS SEMILLA Y PRUEBAS.sql`: inserta datos de ejemplo y prueba el flujo. Se ejecuta una sola vez sobre una base recién preparada.
7. `database/API/Permisos_API.sql`: concede los permisos requeridos por el endpoint actual.

La carpeta `database/Tablas/` también contiene scripts individuales por tabla. Para crear todas las tablas desde cero, usar el script consolidado `ESQUEMA Y TABLAS.sql`; no ejecutar además los scripts individuales sobre las mismas tablas.

La carpeta de procedimientos contiene archivos organizados por entidad y un archivo consolidado. Para la instalación, usar los scripts individuales en el orden de dependencias; evitar ejecutar el consolidado además de los individuales.

Si se vuelve a crear la base desde cero, hay que volver a ejecutar el esquema, control de acceso, procedimientos, funciones, triggers, datos semilla y permisos. Los usuarios y permisos de base de datos se eliminan con ella, aunque los logins del servidor pueden conservarse.

## Ejecución del API

El proyecto del API está en:

```
database/API/Vidauniversitaria.Api/
```

La solución de Visual Studio está en la raíz del repositorio: `NewRepo.slnx`.

La cadena de conexión se obtiene mediante `ConnectionStrings:VidaU`. Para desarrollo local se configura en **Secretos de usuario**; no se debe incluir una contraseña real en GitHub.

En Visual Studio:

1. Abrir `NewRepo.slnx`.
2. Seleccionar el perfil de ejecución `https`.
3. Ejecutar el proyecto.
4. Swagger UI se abre automáticamente. Si no se abre, ingresar a `https://localhost:7170/swagger`.

El API incluye actualmente estos endpoints:

| Método y ruta | Función |

| `GET /api/universidades` | Consulta todas las universidades mediante `VidaU.sp_Universidad_Consultar`. |
| `GET /api/universidades?idUniversidad=1` | Consulta la universidad con identificador `1` mediante el mismo procedimiento. |

El procedimiento recibe `NULL` para listar todas las universidades o un identificador para filtrar por una universidad. El resultado se transforma en un DTO y se devuelve como JSON.

El endpoint fue ejecutado desde Swagger y respondió **HTTP 200** con los datos de la universidad de prueba.

## Control de acceso

Estos son los permisos configurados actualmente en los scripts:

| Usuario SQL | Función prevista | Permisos configurados |

| `app_admin` | Administración | `EXECUTE` sobre el esquema `VidaU`; las escrituras directas en tablas están denegadas. |
| `app_user` | Estudiante | Sin permisos generales sobre el esquema. `Permisos_API.sql` concede `EXECUTE` sobre `VidaU.sp_Universidad_Consultar` para el endpoint actual. |
| `app_readonly` | Consulta | `SELECT` sobre el esquema `VidaU`, excepto la columna `Usuario.Contrasena`; las escrituras directas están denegadas. |

La API no hace operaciones `INSERT`, `UPDATE` ni `DELETE` directamente sobre las tablas. Las operaciones de negocio deben pasar por procedimientos almacenados.

**Estado actual de la API:** utiliza la conexión `VidaU` configurada localmente mediante Secretos de usuario. El endpoint de consulta de universidades ejecuta un procedimiento almacenado. La API todavía no selecciona una conexión según el rol de un token ni implementa JWT o autorización por roles.

Las contraseñas que aparecen en el script de control de acceso son de ejemplo para el entorno de clase. No se deben reutilizar fuera de ese entorno.

## Convenciones

- **Stored procedures:** `sp_<Entidad>_<Acción>` en el código, por ejemplo `sp_Resennia_Agregar`.
- **Restricciones:** prefijos `PK_`, `FK_`, `UQ_`, `CK_` y `DF_` seguidos del nombre de la tabla.
- **Códigos de error:** `50001` duplicado, `50002` no existe, `50003` tiene registros relacionados, `50023` reseña duplicada, `50030` credenciales incorrectas y `50040` suscripción traslapada.
- Los procedimientos de escritura usan `SET NOCOUNT ON` y bloques `TRY...CATCH`.

## Avance del proyecto

| Revisión | Semana | Avance esperado | Estado |

| R1 | 3 | Propuesta aprobada, modelo ER, base de datos, usuarios y roles | Completada |
| R2 | 5 | 40 % de los procedimientos (incluye autenticación) y API ejecutando al menos uno | Completada |
| R3 | 8 | 80 % de los procedimientos y transacciones explícitas | Completada |
| R4 | 12 | Sistema completo y planes de ejecución documentados | Pendiente |
| Final | 15 | Entregables, manual técnico y defensa oral | Pendiente |

Lista de verificación:

- [x] Modelo entidad-relación y modelo relacional
- [x] Esquema de 19 tablas
- [x] Modelos y contexto EF Core generados mediante Scaffold
- [x] Procedimientos almacenados de autenticación, usuarios y CRUD por entidad
- [x] Al menos el 40 % de los procedimientos almacenados, incluidos los de autenticación (R2)
- [x] API REST ejecuta al menos un procedimiento almacenado (R2)
- [x] Al menos el 80 % de los procedimientos almacenados (R3)
- [x] Transacciones explícitas implementadas (63 bloques)
- [x] Funciones (mínimo 2) y triggers (mínimo 1)
- [x] Logins, usuarios y permisos base configurados
- [ ] Permisos mínimos por procedimiento y rol para todas las operaciones del API
- [ ] Procedimientos de reseñas públicas (publicar y leer solo visibles)
- [ ] Reportes de analítica
- [ ] Optimización de consultas y documentación de planes de ejecución
- [ ] API REST con JWT y autorización por rol
- [ ] Manual técnico y presentación final

## Flujo de trabajo en equipo

Antes de comenzar a trabajar, integrar los cambios recientes del repositorio:

```
git pull --no-rebase origin master
```

Después de hacer los cambios, revisar el estado, agregar solo los archivos del proyecto que correspondan, crear el commit y subirlo:

```
git status
git add <archivo-o-carpeta>
git commit -m "Descripción corta del avance"
git push origin master
```

Si el `push` es rechazado porque GitHub tiene cambios nuevos, ejecutar `git pull --no-rebase origin master`, resolver cualquier conflicto y volver a hacer `git push origin master`.

Cada integrante debe hacer commits con su propia cuenta, de modo que el historial refleje su contribución.
