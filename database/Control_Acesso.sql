-- Control de acceso: logins, usuarios y permisos
USE VidaUniversitariaDB
GO

-------------------- CONTROL DE ACCESO -------------------------

/* 
   Control de acceso (logins, usuarios y permisos)
   Principio de mínimo privilegio: cada usuario SQL recibe solo los
   permisos que su rol en la aplicación realmente necesita.
*/


/*
   LOGINS a nivel de servidor
*/

-- app_admin: administración/coordinación. Acceso completo a nivel de
-- esquema (CRUD + analítica + moderación).
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'app_admin')
BEGIN
    CREATE LOGIN app_admin WITH PASSWORD = 'Proyecto_Admin#2026';
END
GO

-- app_user: estudiante. Solo puede ejecutar los procedures de consulta,
-- matrícula y reseñas propias (se otorgará EXECUTE por procedure en la
-- Parte 3, una vez que existan).
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'app_user')
BEGIN
    CREATE LOGIN app_user WITH PASSWORD = 'Proyecto_User#2026';
END
GO

-- app_readonly: coordinador de carrera. Solo lectura, pensada para
-- consultar vistas analíticas (no ejecuta procedures de escritura).
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'app_readonly')
BEGIN
    CREATE LOGIN app_readonly WITH PASSWORD = 'Proyecto_Readonly#2026';
END
GO

/*
   USUARIOS a nivel de base de datos (mapeados a cada login)
*/

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'app_admin')
BEGIN
    CREATE USER app_admin FOR LOGIN app_admin;
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'app_user')
BEGIN
    CREATE USER app_user FOR LOGIN app_user;
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'app_readonly')
BEGIN
    CREATE USER app_readonly FOR LOGIN app_readonly;
END
GO

/*
   PERMISOS A NIVEL DE ESQUEMA (base, se refina por procedure en la Parte 3)

   Importante: ninguno de los tres usuarios recibe permisos directos de
   INSERT/UPDATE/DELETE sobre las tablas. Toda la lógica de negocio pasa
   por stored procedures (según exige el proyecto), así que el acceso
   real se controla otorgando EXECUTE sobre cada procedure puntual.
   Aquí solo se deja la base de SELECT para lectura general y se bloquea
   explícitamente cualquier acceso directo de escritura.
*/

-- app_admin: EXECUTE sobre todo el esquema (todos los procedures,
-- presentes y futuros, gracias al permiso a nivel de esquema).
GRANT EXECUTE ON SCHEMA :: VidaU TO app_admin;
GO

-- app_user: sin permisos generales todavía. Recibirá EXECUTE
-- procedure por procedure en la Parte 3, solo sobre lo que un
-- estudiante debe poder hacer.
-- (Intencionalmente no se otorga nada aquí; mínimo privilegio.)

-- app_readonly: solo SELECT sobre el esquema, para consultar vistas
-- analíticas cuando existan. No tiene EXECUTE sobre procedures.
GRANT SELECT ON SCHEMA :: VidaU TO app_readonly;
GO

-- Bloqueo explícito: ningún usuario de aplicación puede modificar datos
-- directamente sobre las tablas, sin pasar por un stored procedure.
DENY INSERT, UPDATE, DELETE ON SCHEMA :: VidaU TO app_user, app_readonly;
GO

-- app_admin tampoco debería escribir directamente sobre tablas en
-- producción; toda escritura debe ir también por procedure.
DENY INSERT, UPDATE, DELETE ON SCHEMA :: VidaU TO app_admin;
GO

-- Protección de datos sensibles: el SELECT a nivel de esquema incluiría la columna
-- Contrasena (el hash de las contraseñas). Se bloquea para app_readonly; un DENY
-- de columna prevalece sobre el GRANT del esquema.
DENY SELECT ON VidaU.Usuario (Contrasena) TO app_readonly;
GO

/*
   VERIFICACIÓN: usuarios creados y permisos efectivos
*/

-- USUARIOS DE BASE DE DATOS CREADOS Y EL LOGIN AL QUE ESTAN MAPEADOS
SELECT
    dp.name                 AS usuario_bd,
    sp.name                 AS login_servidor
FROM sys.database_principals dp
JOIN sys.server_principals sp ON dp.sid = sp.sid
WHERE dp.name IN ('app_admin','app_user','app_readonly');
GO

-- PERMISOS EFECTIVOS DE CADA USUARIO (GRANT = PERMITIDO, DENY = BLOQUEADO)
SELECT
    pr.name                 AS usuario,
    pe.state_desc           AS estado,
    pe.permission_name      AS permiso,
    pe.class_desc           AS tipo_objeto
FROM sys.database_permissions pe
JOIN sys.database_principals pr ON pe.grantee_principal_id = pr.principal_id
WHERE pr.name IN ('app_admin','app_user','app_readonly')
ORDER BY pr.name, pe.permission_name;
GO

PRINT 'Logins, usuarios y permisos de VidaU configurados correctamente.';
GO
