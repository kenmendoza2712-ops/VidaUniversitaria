# Vida Universitaria

Plataforma SaaS de reseñas de profesores y cursos, con analítica por carrera, facultad y periodo para las universidades.

Proyecto Final de **Bases de Datos II** (BTI23), Escuela de Tecnologías de la Información y Comunicación, Universidad Latina de Costa Rica.

## Integrantes

| Kendall Quesada |kenmendoza2712-ops |
| Maverick Garcia | MavGarciaB |
| Yorleni Rivera | Yorleni-06 |
| Diego Marchena | DiegoMarchena046 |

## Descripción

Los estudiantes consultan y publican reseñas anónimas de las lecciones que cursaron (un curso con un profesor y un horario concretos). Las universidades acceden a una sección analítica con promedios, rankings y evolución de las calificaciones.

**Modelo de negocio:** freemium. Los estudiantes usan la plataforma gratis; las universidades pagan una suscripción (plan mensual o anual) para acceder a la analítica.

## Arquitectura

El sistema sigue tres capas:

```
Cliente (web / Postman)  →  API REST (.NET)  →  SQL Server
```

- **Base de datos:** concentra toda la lógica de negocio mediante stored procedures, funciones y triggers.
- **API REST:** solo recibe la petición HTTP, valida el token (JWT), ejecuta el stored procedure correspondiente y devuelve el resultado en JSON. No contiene lógica de negocio.
- **Cliente de demostración:** aplicación web o colección de Postman.

## Estructura del repositorio

```
VidaUniversitaria/
├── database/
│   ├── 01_esquema_tablas.sql      Base de datos, esquema VidaU y 19 tablas
│   ├── 02_control_acceso.sql      Logins, usuarios y permisos
│   └── 03_procedures_*.sql        Stored procedures, funciones y triggers (en progreso)
├── docs/                          Diagramas entidad-relación y relacional
├── api/                           API REST en .NET (pendiente)
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
- Las contraseñas se guardan con `HASHBYTES`, nunca en texto plano.
- `Plan` es palabra reservada de SQL Server, por eso se escribe `VidaU.[Plan]` con corchetes.

## Requisitos

- SQL Server 2019 o superior (o SQL Server Express)
- SQL Server Management Studio (SSMS)
- Una cuenta con permisos de `sysadmin` en la instancia (necesaria para crear la base de datos y los logins)

## Instalación y ejecución

1. Clonar el repositorio:
   ```bash
   git clone https://github.com/kenmendoza2712-ops/VidaUniversitaria.git
   ```
2. Abrir SSMS y conectarse a la instancia de SQL Server.
3. Ejecutar **en orden** los scripts de la carpeta `database/`:
   1. `01_esquema_tablas.sql`: crea la base de datos `VidaUniversitariaDB`, el esquema `VidaU` y las 19 tablas.
   2. `02_control_acceso.sql`: crea los logins, usuarios y permisos.
   3. `03_procedures_*.sql`: crea los stored procedures, funciones y triggers (cuando estén disponibles).
4. Confirmar que no hubo errores. Cada script termina con un mensaje de confirmación.

Si se vuelve a crear la base de datos desde cero, hay que volver a correr `02_control_acceso.sql`: los usuarios de la base se eliminan con ella, aunque los logins del servidor se conservan.

## Control de acceso

El API nunca se conecta con `sa` ni con permisos de `dbo`. Cada usuario tiene los permisos mínimos que necesita:

| Usuario SQL | Rol en la aplicación | Permisos |
|---|---|---|
| `app_admin` | Administración y coordinación | `EXECUTE` sobre el esquema `VidaU` |
| `app_user` | Estudiante | `EXECUTE` solo sobre los procedures de estudiante |
| `app_readonly` | Coordinador de carrera | `SELECT` sobre el esquema (sin acceso a `Usuario.Contrasena`) |

Ningún usuario puede hacer `INSERT`, `UPDATE` ni `DELETE` directo sobre las tablas: toda escritura pasa por un stored procedure.

Las contraseñas de los logins se definen en `02_control_acceso.sql`. Son de ejemplo para el entorno de clase y deben cambiarse en cualquier otro entorno. La cadena de conexión del API irá en variables de entorno o en un archivo `.env` excluido del repositorio.

## Convenciones

- **Stored procedures:** `usp_<Entidad>_<Acción>`, por ejemplo `usp_Resennia_Crear`.
- **Restricciones:** prefijos `PK_`, `FK_`, `UQ_`, `CK_` y `DF_` seguidos del nombre de la tabla.
- Cada stored procedure inicia con `SET NOCOUNT ON`, usa `TRY...CATCH` y lleva un comentario de cabecera con nombre, descripción, parámetros, autor y fecha.

## Avance del proyecto

| Revisión | Semana | Avance esperado | Estado |
|---|---|---|---|
| R1 | 3 | Propuesta aprobada, modelo ER, base de datos creada, usuarios y roles | En curso |
| R2 | 5 | 40 % de los procedures (incluye autenticación) y API ejecutando al menos uno | Pendiente |
| R3 | 8 | 80 % de los procedures y transacciones explícitas | Pendiente |
| R4 | 12 | Sistema completo y planes de ejecución documentados | Pendiente |
| Final | 15 | Todos los entregables, manual técnico y defensa oral | Pendiente |

Lista de verificación:

- [x] Modelo entidad-relación y modelo relacional
- [x] Esquema de 19 tablas (`01_esquema_tablas.sql`)
- [x] Control de acceso (`02_control_acceso.sql`)
- [ ] Stored procedures de usuarios y login
- [ ] Stored procedures del resto de entidades
- [ ] Transacciones explícitas (mínimo 3)
- [ ] Funciones (mínimo 2) y trigger (mínimo 1)
- [ ] Optimización de consultas con planes de ejecución
- [ ] API REST con JWT
- [ ] Manual técnico y presentación

## Flujo de trabajo en equipo

```bash
git pull                                   # traer los cambios antes de empezar
git add .
git commit -m "Descripción corta del avance"
git push
```

Cada integrante hace commits con su propia cuenta, de modo que el historial refleje la contribución de cada uno.
