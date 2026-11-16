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

## Estructura del repositorio

```text
NewRepo/
├── database/
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

## Requisitos

- SQL Server 2019 o superior (SQL Server Express sirve para desarrollo local).
- SQL Server Management Studio (SSMS).
- Visual Studio Community 2026 con la carga de trabajo de ASP.NET y web, y el SDK de .NET 10.
- Acceso al repositorio de GitHub.
- Una cuenta administrativa local de SQL Server para crear la base de datos y los logins durante la instalación.

## Preparar SQL Server

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

## Control de acceso

El script `Control_Acceso.sql` define `app_admin`, `app_user` y `app_readonly`, con permisos separados. `Permisos_API.sql` concede a `app_user` solo el `EXECUTE` requerido por el endpoint de consulta de universidades. Los permisos adicionales deben agregarse de forma puntual cuando se implementen y protejan nuevos endpoints.

## Pruebas disponibles

`DATOS SEMILLA Y PRUEBAS.sql` valida varios flujos llamando a los procedimientos almacenados. Entre sus resultados esperados están el error `50030` para contraseña incorrecta, el error `50023` para una reseña duplicada y un promedio de `4.50` para tres evaluaciones. Esos errores son parte de pruebas esperadas, no indican por sí solos que la ejecución haya fallado.

La ruta `GET /api/universidades` es la comprobación de integración actual entre HTTP, la API y SQL Server.

## Lineamientos y próximos entregables

El diseño mantiene la lógica de negocio en SQL Server. La API debe limitarse a autenticar y autorizar la petición, ejecutar el procedimiento correspondiente y serializar la respuesta. El trabajo pendiente para completar los entregables incluye, entre otros puntos:

- Autenticación JWT con expiración máxima de ocho horas y autorización de endpoints por rol.
- Mapeo consistente de errores de SQL Server a códigos HTTP.
- Cliente de demostración, que puede ser una colección de Postman.
- Selección de tres consultas críticas y documentación de sus planes antes y después de optimizarlas.
- Manual técnico en PDF de al menos 20 páginas y presentación con demostración en vivo.

Cada nuevo script SQL debe llevar una cabecera que explique su propósito, requisitos previos, parámetros o datos que utiliza, orden de ejecución, efectos esperados y advertencias sobre si puede repetirse.

## Trabajo en equipo

Antes de empezar, actualiza la copia local:

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
