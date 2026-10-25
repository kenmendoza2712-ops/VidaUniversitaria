-- ============================================================================
-- Vida Universitaria: creacion de TODOS los procedimientos almacenados
-- Contenido: 85 procedimientos + 1 funcion (esquema VidaU).
-- Es una copia de los 28 archivos de las carpetas, en orden y SIN modificar,
-- para ejecutarlos de una sola vez. La funcion fn_Auth_IntentosFallidos va antes
-- que sp_Auth_Login y sp_Auth_CambiarContrasena, que la usan.
-- REQUISITO: haber ejecutado antes el script de tablas (01) y el de control de acceso (02).
-- ============================================================================
USE VidaUniversitariaDB
GO

-- >>>>>> Archivo: Tablas sin dependencias/Rol_ProcedimientosAlmacenados.sql
/* "Rol" */
 
-- Agrega un rol nuevo. Respeta UQ_Rol_Nombre (no se repite el nombre).
CREATE OR ALTER PROCEDURE VidaU.sp_Rol_Agregar
    @Nombre      VARCHAR(50),
    @Descripcion VARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON; -- ROLLBACK AUTOMATICO ANTE CUALQUIER ERROR DE EJECUCION
    BEGIN TRY
        BEGIN TRANSACTION;
 
        -- UPDLOCK + HOLDLOCK BLOQUEA EL RANGO PARA QUE OTRA SESION NO INSERTE EL MISMO NOMBRE A LA VEZ
        IF EXISTS (SELECT 1 FROM VidaU.Rol WITH (UPDLOCK, HOLDLOCK) WHERE Nombre = @Nombre) -- VALIDA QUE NO EXISTA OTRO ROL CON EL MISMO NOMBRE
            THROW 50001, 'Ya existe un rol con ese nombre.', 1;
 
        INSERT INTO VidaU.Rol (Nombre, Descripcion)
        VALUES (@Nombre, @Descripcion);
 
        DECLARE @idNuevo INT = SCOPE_IDENTITY(); -- ID GENERADO POR IDENTITY
 
        COMMIT TRANSACTION;
        SELECT @idNuevo AS idRol; -- DEVUELVE EL ID GENERADO
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION; -- DESHACE TODO SI ALGO FALLO
        THROW;
    END CATCH
END
GO
 
-- Actualiza el nombre y la descripción de un rol existente.
CREATE OR ALTER PROCEDURE VidaU.sp_Rol_Actualizar
    @idRol       INT,
    @Nombre      VARCHAR(50),
    @Descripcion VARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
 
        IF NOT EXISTS (SELECT 1 FROM VidaU.Rol WITH (UPDLOCK, HOLDLOCK) WHERE idRol = @idRol) -- BLOQUEA EL REGISTRO A MODIFICAR
            THROW 50002, 'El rol indicado no existe.', 1;
 
        IF EXISTS (SELECT 1 FROM VidaU.Rol WITH (UPDLOCK, HOLDLOCK) WHERE Nombre = @Nombre AND idRol <> @idRol) -- EXCLUYE EL PROPIO REGISTRO
            THROW 50001, 'Ya existe otro rol con ese nombre.', 1;
 
        UPDATE VidaU.Rol
        SET Nombre = @Nombre,
            Descripcion = @Descripcion
        WHERE idRol = @idRol;
 
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO
 
-- Elimina un rol. Si está referenciado por otras tablas (ej. Usuario), se informa el error.
CREATE OR ALTER PROCEDURE VidaU.sp_Rol_Eliminar
    @idRol INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
 
        IF NOT EXISTS (SELECT 1 FROM VidaU.Rol WITH (UPDLOCK, HOLDLOCK) WHERE idRol = @idRol)
            THROW 50002, 'El rol indicado no existe.', 1;
 
        DELETE FROM VidaU.Rol WHERE idRol = @idRol;
 
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        DECLARE @Err INT = ERROR_NUMBER(); -- SE GUARDA ANTES DEL ROLLBACK
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        IF @Err = 547 -- ERROR DE LLAVE FORANEA
            THROW 50003, 'No se puede eliminar el rol porque tiene registros relacionados.', 1;
        THROW;
    END CATCH
END
GO
 
-- Consulta un rol por id, o todos los roles si @idRol es NULL.
-- SOLO LECTURA: NO NECESITA TRANSACCION EXPLICITA
CREATE OR ALTER PROCEDURE VidaU.sp_Rol_Consultar
    @idRol INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT idRol, Nombre, Descripcion
    FROM VidaU.Rol
    WHERE (@idRol IS NULL OR idRol = @idRol)
    ORDER BY idRol;
END
GO

-- >>>>>> Archivo: Tablas sin dependencias/Plan_ProcedimientosAlmacenados.sql
/* "Plan" */
 
-- Agrega un plan nuevo. Respeta CK_Plan_Monto (Monto >= 0).
-- PLAN ES PALABRA RESERVADA, POR ESO SE ESCRIBE ENTRE CORCHETES [Plan]
CREATE OR ALTER PROCEDURE VidaU.sp_Plan_Agregar
    @Nombre      VARCHAR(100),
    @Descripcion VARCHAR(300) = NULL,
    @Monto       DECIMAL(10,2)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON; -- ROLLBACK AUTOMATICO ANTE CUALQUIER ERROR DE EJECUCION
    BEGIN TRY
        IF @Monto < 0 -- VALIDA LA REGLA DEL CHECK ANTES DE ABRIR LA TRANSACCION
            THROW 50004, 'El monto debe ser mayor o igual a 0.', 1;
 
        BEGIN TRANSACTION;
 
        INSERT INTO VidaU.[Plan] (Nombre, Descripcion, Monto)
        VALUES (@Nombre, @Descripcion, @Monto);
 
        DECLARE @idNuevo INT = SCOPE_IDENTITY(); -- ID GENERADO POR IDENTITY
 
        COMMIT TRANSACTION;
        SELECT @idNuevo AS idPlan;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION; -- DESHACE TODO SI ALGO FALLO
        THROW;
    END CATCH
END
GO
 
-- Actualiza nombre, descripción y monto de un plan existente.
CREATE OR ALTER PROCEDURE VidaU.sp_Plan_Actualizar
    @idPlan      INT,
    @Nombre      VARCHAR(100),
    @Descripcion VARCHAR(300) = NULL,
    @Monto       DECIMAL(10,2)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        IF @Monto < 0
            THROW 50004, 'El monto debe ser mayor o igual a 0.', 1;
 
        BEGIN TRANSACTION;
 
        -- UPDLOCK + HOLDLOCK BLOQUEA EL REGISTRO PARA QUE OTRA SESION NO LO ELIMINE O MODIFIQUE MIENTRAS SE ACTUALIZA
        IF NOT EXISTS (SELECT 1 FROM VidaU.[Plan] WITH (UPDLOCK, HOLDLOCK) WHERE idPlan = @idPlan)
            THROW 50002, 'El plan indicado no existe.', 1;
 
        UPDATE VidaU.[Plan]
        SET Nombre = @Nombre,
            Descripcion = @Descripcion,
            Monto = @Monto
        WHERE idPlan = @idPlan;
 
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO
 
-- Elimina un plan. Si tiene suscripciones relacionadas, se informa el error.
CREATE OR ALTER PROCEDURE VidaU.sp_Plan_Eliminar
    @idPlan INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
 
        IF NOT EXISTS (SELECT 1 FROM VidaU.[Plan] WITH (UPDLOCK, HOLDLOCK) WHERE idPlan = @idPlan)
            THROW 50002, 'El plan indicado no existe.', 1;
 
        DELETE FROM VidaU.[Plan] WHERE idPlan = @idPlan;
 
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        DECLARE @Err INT = ERROR_NUMBER(); -- SE GUARDA ANTES DEL ROLLBACK
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        IF @Err = 547 -- ERROR DE LLAVE FORANEA
            THROW 50003, 'No se puede eliminar el plan porque tiene registros relacionados.', 1;
        THROW;
    END CATCH
END
GO
 
-- Consulta un plan por id, o todos los planes si @idPlan es NULL.
-- SOLO LECTURA: NO NECESITA TRANSACCION EXPLICITA
CREATE OR ALTER PROCEDURE VidaU.sp_Plan_Consultar
    @idPlan INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT idPlan, Nombre, Descripcion, Monto
    FROM VidaU.[Plan]
    WHERE (@idPlan IS NULL OR idPlan = @idPlan)
    ORDER BY idPlan;
END
GO

-- >>>>>> Archivo: Tablas sin dependencias/Universidad_ProcedimientosAlmacenados.sql
/* "Universidad" */
 
-- Agrega una universidad. Respeta UQ_Universidad_Correo y CK_Universidad_Estado.
-- SI @Estado ES NULL SE USA EL VALOR POR DEFECTO 'Activa'
CREATE OR ALTER PROCEDURE VidaU.sp_Universidad_Agregar
    @Nombre   VARCHAR(150),
    @Correo   VARCHAR(150),
    @Estado   VARCHAR(20) = NULL,
    @Telefono VARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON; -- ROLLBACK AUTOMATICO ANTE CUALQUIER ERROR DE EJECUCION
    BEGIN TRY
        SET @Estado = ISNULL(@Estado, 'Activa');
 
        IF @Estado NOT IN ('Activa','Inactiva') -- VALIDA LA REGLA DEL CHECK ANTES DE ABRIR LA TRANSACCION
            THROW 50005, 'El estado debe ser Activa o Inactiva.', 1;
 
        BEGIN TRANSACTION;
 
        -- UPDLOCK + HOLDLOCK BLOQUEA EL RANGO PARA QUE OTRA SESION NO INSERTE EL MISMO CORREO A LA VEZ
        IF EXISTS (SELECT 1 FROM VidaU.Universidad WITH (UPDLOCK, HOLDLOCK) WHERE Correo = @Correo) -- VALIDA CORREO UNICO
            THROW 50001, 'Ya existe una universidad con ese correo.', 1;
 
        INSERT INTO VidaU.Universidad (Nombre, Correo, Estado, Telefono)
        VALUES (@Nombre, @Correo, @Estado, @Telefono);
 
        DECLARE @idNuevo INT = SCOPE_IDENTITY(); -- ID GENERADO POR IDENTITY
 
        COMMIT TRANSACTION;
        SELECT @idNuevo AS idUniversidad;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION; -- DESHACE TODO SI ALGO FALLO
        THROW;
    END CATCH
END
GO
 
-- Actualiza los datos de una universidad existente.
CREATE OR ALTER PROCEDURE VidaU.sp_Universidad_Actualizar
    @idUniversidad INT,
    @Nombre        VARCHAR(150),
    @Correo        VARCHAR(150),
    @Estado        VARCHAR(20),
    @Telefono      VARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        IF @Estado NOT IN ('Activa','Inactiva')
            THROW 50005, 'El estado debe ser Activa o Inactiva.', 1;
 
        BEGIN TRANSACTION;
 
        IF NOT EXISTS (SELECT 1 FROM VidaU.Universidad WITH (UPDLOCK, HOLDLOCK) WHERE idUniversidad = @idUniversidad) -- BLOQUEA EL REGISTRO A MODIFICAR
            THROW 50002, 'La universidad indicada no existe.', 1;
 
        IF EXISTS (SELECT 1 FROM VidaU.Universidad WITH (UPDLOCK, HOLDLOCK) WHERE Correo = @Correo AND idUniversidad <> @idUniversidad) -- EXCLUYE EL PROPIO REGISTRO
            THROW 50001, 'Ya existe otra universidad con ese correo.', 1;
 
        UPDATE VidaU.Universidad
        SET Nombre = @Nombre,
            Correo = @Correo,
            Estado = @Estado,
            Telefono = @Telefono
        WHERE idUniversidad = @idUniversidad;
 
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO
 
-- Elimina una universidad. Si tiene sedes, suscripciones o profesores relacionados, se informa el error.
CREATE OR ALTER PROCEDURE VidaU.sp_Universidad_Eliminar
    @idUniversidad INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
 
        IF NOT EXISTS (SELECT 1 FROM VidaU.Universidad WITH (UPDLOCK, HOLDLOCK) WHERE idUniversidad = @idUniversidad)
            THROW 50002, 'La universidad indicada no existe.', 1;
 
        DELETE FROM VidaU.Universidad WHERE idUniversidad = @idUniversidad;
 
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        DECLARE @Err INT = ERROR_NUMBER(); -- SE GUARDA ANTES DEL ROLLBACK
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        IF @Err = 547 -- ERROR DE LLAVE FORANEA
            THROW 50003, 'No se puede eliminar la universidad porque tiene registros relacionados.', 1;
        THROW;
    END CATCH
END
GO
 
-- Consulta una universidad por id, o todas si @idUniversidad es NULL.
-- SOLO LECTURA: NO NECESITA TRANSACCION EXPLICITA
CREATE OR ALTER PROCEDURE VidaU.sp_Universidad_Consultar
    @idUniversidad INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT idUniversidad, Nombre, Correo, Estado, Telefono
    FROM VidaU.Universidad
    WHERE (@idUniversidad IS NULL OR idUniversidad = @idUniversidad)
    ORDER BY idUniversidad;
END
GO
 

-- >>>>>> Archivo: Tablas sin dependencias/Carrera_ProcedimientosAlmacenados.sql
/* "Carrera" */
 
-- Agrega una carrera nueva.
CREATE OR ALTER PROCEDURE VidaU.sp_Carrera_Agregar
    @Nombre      VARCHAR(150),
    @Descripcion VARCHAR(300) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON; -- ROLLBACK AUTOMATICO ANTE CUALQUIER ERROR DE EJECUCION
    BEGIN TRY
        BEGIN TRANSACTION;
 
        INSERT INTO VidaU.Carrera (Nombre, Descripcion)
        VALUES (@Nombre, @Descripcion);
 
        DECLARE @idNuevo INT = SCOPE_IDENTITY(); -- ID GENERADO POR IDENTITY
 
        COMMIT TRANSACTION;
        SELECT @idNuevo AS idCarrera;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION; -- DESHACE TODO SI ALGO FALLO
        THROW;
    END CATCH
END
GO
 
-- Actualiza nombre y descripción de una carrera existente.
CREATE OR ALTER PROCEDURE VidaU.sp_Carrera_Actualizar
    @idCarrera   INT,
    @Nombre      VARCHAR(150),
    @Descripcion VARCHAR(300) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
 
        -- UPDLOCK + HOLDLOCK BLOQUEA EL REGISTRO PARA QUE OTRA SESION NO LO ELIMINE O MODIFIQUE MIENTRAS SE ACTUALIZA
        IF NOT EXISTS (SELECT 1 FROM VidaU.Carrera WITH (UPDLOCK, HOLDLOCK) WHERE idCarrera = @idCarrera)
            THROW 50002, 'La carrera indicada no existe.', 1;
 
        UPDATE VidaU.Carrera
        SET Nombre = @Nombre,
            Descripcion = @Descripcion
        WHERE idCarrera = @idCarrera;
 
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO
 
-- Elimina una carrera. Si está en tablas puente (Sede_Carrera, Carrera_Curso, Carrera_Estudiante), se informa el error.
CREATE OR ALTER PROCEDURE VidaU.sp_Carrera_Eliminar
    @idCarrera INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
 
        IF NOT EXISTS (SELECT 1 FROM VidaU.Carrera WITH (UPDLOCK, HOLDLOCK) WHERE idCarrera = @idCarrera)
            THROW 50002, 'La carrera indicada no existe.', 1;
 
        DELETE FROM VidaU.Carrera WHERE idCarrera = @idCarrera;
 
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        DECLARE @Err INT = ERROR_NUMBER(); -- SE GUARDA ANTES DEL ROLLBACK
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        IF @Err = 547 -- ERROR DE LLAVE FORANEA
            THROW 50003, 'No se puede eliminar la carrera porque tiene registros relacionados.', 1;
        THROW;
    END CATCH
END
GO
 
-- Consulta una carrera por id, o todas si @idCarrera es NULL.
-- SOLO LECTURA: NO NECESITA TRANSACCION EXPLICITA
CREATE OR ALTER PROCEDURE VidaU.sp_Carrera_Consultar
    @idCarrera INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT idCarrera, Nombre, Descripcion
    FROM VidaU.Carrera
    WHERE (@idCarrera IS NULL OR idCarrera = @idCarrera)
    ORDER BY idCarrera;
END
GO

-- >>>>>> Archivo: Tablas sin dependencias/Curso_ProcedimientosAlmacenados.sql
/* "Curso" */
 
-- Agrega un curso nuevo. Respeta CK_Curso_Creditos (Creditos > 0).
CREATE OR ALTER PROCEDURE VidaU.sp_Curso_Agregar
    @Nombre      VARCHAR(150),
    @Descripcion VARCHAR(300) = NULL,
    @Creditos    INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON; -- ROLLBACK AUTOMATICO ANTE CUALQUIER ERROR DE EJECUCION
    BEGIN TRY
        IF @Creditos <= 0 -- VALIDA LA REGLA DEL CHECK ANTES DE ABRIR LA TRANSACCION
            THROW 50006, 'Los créditos deben ser mayores a 0.', 1;
 
        BEGIN TRANSACTION;
 
        INSERT INTO VidaU.Curso (Nombre, Descripcion, Creditos)
        VALUES (@Nombre, @Descripcion, @Creditos);
 
        DECLARE @idNuevo INT = SCOPE_IDENTITY(); -- ID GENERADO POR IDENTITY
 
        COMMIT TRANSACTION;
        SELECT @idNuevo AS idCurso;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION; -- DESHACE TODO SI ALGO FALLO
        THROW;
    END CATCH
END
GO
 
-- Actualiza nombre, descripción y créditos de un curso existente.
CREATE OR ALTER PROCEDURE VidaU.sp_Curso_Actualizar
    @idCurso     INT,
    @Nombre      VARCHAR(150),
    @Descripcion VARCHAR(300) = NULL,
    @Creditos    INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        IF @Creditos <= 0
            THROW 50006, 'Los créditos deben ser mayores a 0.', 1;
 
        BEGIN TRANSACTION;
 
        -- UPDLOCK + HOLDLOCK BLOQUEA EL REGISTRO PARA QUE OTRA SESION NO LO ELIMINE O MODIFIQUE MIENTRAS SE ACTUALIZA
        IF NOT EXISTS (SELECT 1 FROM VidaU.Curso WITH (UPDLOCK, HOLDLOCK) WHERE idCurso = @idCurso)
            THROW 50002, 'El curso indicado no existe.', 1;
 
        UPDATE VidaU.Curso
        SET Nombre = @Nombre,
            Descripcion = @Descripcion,
            Creditos = @Creditos
        WHERE idCurso = @idCurso;
 
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO
 
-- Elimina un curso. Si tiene lecciones o está en Carrera_Curso, se informa el error.
CREATE OR ALTER PROCEDURE VidaU.sp_Curso_Eliminar
    @idCurso INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
 
        IF NOT EXISTS (SELECT 1 FROM VidaU.Curso WITH (UPDLOCK, HOLDLOCK) WHERE idCurso = @idCurso)
            THROW 50002, 'El curso indicado no existe.', 1;
 
        DELETE FROM VidaU.Curso WHERE idCurso = @idCurso;
 
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        DECLARE @Err INT = ERROR_NUMBER(); -- SE GUARDA ANTES DEL ROLLBACK
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        IF @Err = 547 -- ERROR DE LLAVE FORANEA
            THROW 50003, 'No se puede eliminar el curso porque tiene registros relacionados.', 1;
        THROW;
    END CATCH
END
GO
 
-- Consulta un curso por id, o todos si @idCurso es NULL.
-- SOLO LECTURA: NO NECESITA TRANSACCION EXPLICITA
CREATE OR ALTER PROCEDURE VidaU.sp_Curso_Consultar
    @idCurso INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT idCurso, Nombre, Descripcion, Creditos
    FROM VidaU.Curso
    WHERE (@idCurso IS NULL OR idCurso = @idCurso)
    ORDER BY idCurso;
END
GO
 

-- >>>>>> Archivo: Tablas sin dependencias/Profesor_ProcedimientosAlmacenados.sql
/* "Profesor" */
 
-- Agrega un profesor nuevo. Respeta UQ_Profesor_Correo (no se repite el correo).
CREATE OR ALTER PROCEDURE VidaU.sp_Profesor_Agregar
    @Nombre   VARCHAR(100),
    @Apellido VARCHAR(100),
    @Correo   VARCHAR(150)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON; -- ROLLBACK AUTOMATICO ANTE CUALQUIER ERROR DE EJECUCION
    BEGIN TRY
        BEGIN TRANSACTION;
 
        -- UPDLOCK + HOLDLOCK BLOQUEA EL RANGO PARA QUE OTRA SESION NO INSERTE EL MISMO CORREO A LA VEZ
        IF EXISTS (SELECT 1 FROM VidaU.Profesor WITH (UPDLOCK, HOLDLOCK) WHERE Correo = @Correo) -- VALIDA CORREO UNICO
            THROW 50001, 'Ya existe un profesor con ese correo.', 1;
 
        INSERT INTO VidaU.Profesor (Nombre, Apellido, Correo)
        VALUES (@Nombre, @Apellido, @Correo);
 
        DECLARE @idNuevo INT = SCOPE_IDENTITY(); -- ID GENERADO POR IDENTITY
 
        COMMIT TRANSACTION;
        SELECT @idNuevo AS idProfesor;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION; -- DESHACE TODO SI ALGO FALLO
        THROW;
    END CATCH
END
GO
 
-- Actualiza nombre, apellido y correo de un profesor existente.
CREATE OR ALTER PROCEDURE VidaU.sp_Profesor_Actualizar
    @idProfesor INT,
    @Nombre     VARCHAR(100),
    @Apellido   VARCHAR(100),
    @Correo     VARCHAR(150)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
 
        IF NOT EXISTS (SELECT 1 FROM VidaU.Profesor WITH (UPDLOCK, HOLDLOCK) WHERE idProfesor = @idProfesor) -- BLOQUEA EL REGISTRO A MODIFICAR
            THROW 50002, 'El profesor indicado no existe.', 1;
 
        IF EXISTS (SELECT 1 FROM VidaU.Profesor WITH (UPDLOCK, HOLDLOCK) WHERE Correo = @Correo AND idProfesor <> @idProfesor) -- EXCLUYE EL PROPIO REGISTRO
            THROW 50001, 'Ya existe otro profesor con ese correo.', 1;
 
        UPDATE VidaU.Profesor
        SET Nombre = @Nombre,
            Apellido = @Apellido,
            Correo = @Correo
        WHERE idProfesor = @idProfesor;
 
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO
 
-- Elimina un profesor. Si tiene lecciones o está en Universidad_Profesor, se informa el error.
CREATE OR ALTER PROCEDURE VidaU.sp_Profesor_Eliminar
    @idProfesor INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
 
        IF NOT EXISTS (SELECT 1 FROM VidaU.Profesor WITH (UPDLOCK, HOLDLOCK) WHERE idProfesor = @idProfesor)
            THROW 50002, 'El profesor indicado no existe.', 1;
 
        DELETE FROM VidaU.Profesor WHERE idProfesor = @idProfesor;
 
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        DECLARE @Err INT = ERROR_NUMBER(); -- SE GUARDA ANTES DEL ROLLBACK
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        IF @Err = 547 -- ERROR DE LLAVE FORANEA
            THROW 50003, 'No se puede eliminar el profesor porque tiene registros relacionados.', 1;
        THROW;
    END CATCH
END
GO
 
-- Consulta un profesor por id, o todos si @idProfesor es NULL.
-- SOLO LECTURA: NO NECESITA TRANSACCION EXPLICITA
CREATE OR ALTER PROCEDURE VidaU.sp_Profesor_Consultar
    @idProfesor INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT idProfesor, Nombre, Apellido, Correo
    FROM VidaU.Profesor
    WHERE (@idProfesor IS NULL OR idProfesor = @idProfesor)
    ORDER BY idProfesor;
END
GO

-- >>>>>> Archivo: Tablas de primer nivel/Sede_ProcedimientosAlmacenados.sql
/* "Sede" */
 
-- Agrega una sede nueva. Respeta FK_Sede_Universidad y CK_Sede_Estado.
-- SI @Estado ES NULL SE USA EL VALOR POR DEFECTO 'Activa'
CREATE OR ALTER PROCEDURE VidaU.sp_Sede_Agregar
    @idUniversidad INT,
    @Nombre        VARCHAR(150),
    @Estado        VARCHAR(20) = NULL,
    @Direccion     VARCHAR(250) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON; -- ROLLBACK AUTOMATICO ANTE CUALQUIER ERROR DE EJECUCION
    BEGIN TRY
        SET @Estado = ISNULL(@Estado, 'Activa');
 
        IF @Estado NOT IN ('Activa','Inactiva') -- VALIDA LA REGLA DEL CHECK ANTES DE ABRIR LA TRANSACCION
            THROW 50005, 'El estado debe ser Activa o Inactiva.', 1;
 
        BEGIN TRANSACTION;
 
        IF NOT EXISTS (SELECT 1 FROM VidaU.Universidad WITH (HOLDLOCK) WHERE idUniversidad = @idUniversidad) -- VALIDA LA LLAVE FORANEA
            THROW 50007, 'La universidad indicada no existe.', 1;
 
        INSERT INTO VidaU.Sede (idUniversidad, Nombre, Estado, Direccion)
        VALUES (@idUniversidad, @Nombre, @Estado, @Direccion);
 
        DECLARE @idNuevo INT = SCOPE_IDENTITY(); -- ID GENERADO POR IDENTITY
 
        COMMIT TRANSACTION;
        SELECT @idNuevo AS idSede;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION; -- DESHACE TODO SI ALGO FALLO
        THROW;
    END CATCH
END
GO
 
-- Actualiza los datos de una sede existente.
CREATE OR ALTER PROCEDURE VidaU.sp_Sede_Actualizar
    @idSede        INT,
    @idUniversidad INT,
    @Nombre        VARCHAR(150),
    @Estado        VARCHAR(20),
    @Direccion     VARCHAR(250) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        IF @Estado NOT IN ('Activa','Inactiva')
            THROW 50005, 'El estado debe ser Activa o Inactiva.', 1;
 
        BEGIN TRANSACTION;
 
        IF NOT EXISTS (SELECT 1 FROM VidaU.Sede WITH (UPDLOCK, HOLDLOCK) WHERE idSede = @idSede) -- BLOQUEA EL REGISTRO A MODIFICAR
            THROW 50002, 'La sede indicada no existe.', 1;
 
        IF NOT EXISTS (SELECT 1 FROM VidaU.Universidad WITH (HOLDLOCK) WHERE idUniversidad = @idUniversidad)
            THROW 50007, 'La universidad indicada no existe.', 1;
 
        UPDATE VidaU.Sede
        SET idUniversidad = @idUniversidad,
            Nombre = @Nombre,
            Estado = @Estado,
            Direccion = @Direccion
        WHERE idSede = @idSede;
 
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO
 
-- Elimina una sede. Si está en Sede_Carrera u otras tablas relacionadas, se informa el error.
CREATE OR ALTER PROCEDURE VidaU.sp_Sede_Eliminar
    @idSede INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
 
        IF NOT EXISTS (SELECT 1 FROM VidaU.Sede WITH (UPDLOCK, HOLDLOCK) WHERE idSede = @idSede)
            THROW 50002, 'La sede indicada no existe.', 1;
 
        DELETE FROM VidaU.Sede WHERE idSede = @idSede;
 
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        DECLARE @Err INT = ERROR_NUMBER(); -- SE GUARDA ANTES DEL ROLLBACK
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        IF @Err = 547 -- ERROR DE LLAVE FORANEA
            THROW 50003, 'No se puede eliminar la sede porque tiene registros relacionados.', 1;
        THROW;
    END CATCH
END
GO
 
-- Consulta una sede por id, o todas si @idSede es NULL.
-- SOLO LECTURA: NO NECESITA TRANSACCION EXPLICITA
CREATE OR ALTER PROCEDURE VidaU.sp_Sede_Consultar
    @idSede INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT idSede, idUniversidad, Nombre, Estado, Direccion
    FROM VidaU.Sede
    WHERE (@idSede IS NULL OR idSede = @idSede)
    ORDER BY idSede;
END
GO
 

-- >>>>>> Archivo: Tablas de primer nivel/Suscripcion_ProcedimientosAlmacenados.sql
/* "Suscripcion" */
 
-- Agrega una suscripción nueva. Respeta FK_Suscripcion_Universidad, FK_Suscripcion_Plan,
-- CK_Suscripcion_Estado y CK_Suscripcion_Fechas.
-- SI @Estado ES NULL SE USA EL VALOR POR DEFECTO 'Activa'
CREATE OR ALTER PROCEDURE VidaU.sp_Suscripcion_Agregar
    @idUniversidad INT,
    @idPlan        INT,
    @Estado        VARCHAR(20) = NULL,
    @FechaInicio   DATE,
    @FechaFin      DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        SET @Estado = ISNULL(@Estado, 'Activa');
 
        IF @Estado NOT IN ('Activa','Inactiva','Vencida') -- VALIDA LA REGLA DEL CHECK DE ESTADO
            THROW 50009, 'El estado debe ser Activa, Inactiva o Vencida.', 1;
 
        IF @FechaFin IS NOT NULL AND @FechaFin < @FechaInicio -- VALIDA LA REGLA DEL CHECK DE FECHAS
            THROW 50010, 'La fecha de fin debe ser nula o mayor o igual a la fecha de inicio.', 1;
 
        BEGIN TRANSACTION;
 
        IF NOT EXISTS (SELECT 1 FROM VidaU.Universidad WITH (HOLDLOCK) WHERE idUniversidad = @idUniversidad)
            THROW 50007, 'La universidad indicada no existe.', 1;
 
        IF NOT EXISTS (SELECT 1 FROM VidaU.[Plan] WITH (HOLDLOCK) WHERE idPlan = @idPlan)
            THROW 50008, 'El plan indicado no existe.', 1;
 
        INSERT INTO VidaU.Suscripcion (idUniversidad, idPlan, Estado, FechaInicio, FechaFin)
        VALUES (@idUniversidad, @idPlan, @Estado, @FechaInicio, @FechaFin);
 
        DECLARE @idNuevo INT = SCOPE_IDENTITY();
 
        COMMIT TRANSACTION;
        SELECT @idNuevo AS idSuscripcion;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO
 
-- Actualiza los datos de una suscripción existente.
CREATE OR ALTER PROCEDURE VidaU.sp_Suscripcion_Actualizar
    @idSuscripcion INT,
    @idUniversidad INT,
    @idPlan        INT,
    @Estado        VARCHAR(20),
    @FechaInicio   DATE,
    @FechaFin      DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        IF @Estado NOT IN ('Activa','Inactiva','Vencida')
            THROW 50009, 'El estado debe ser Activa, Inactiva o Vencida.', 1;
 
        IF @FechaFin IS NOT NULL AND @FechaFin < @FechaInicio
            THROW 50010, 'La fecha de fin debe ser nula o mayor o igual a la fecha de inicio.', 1;
 
        BEGIN TRANSACTION;
 
        IF NOT EXISTS (SELECT 1 FROM VidaU.Suscripcion WITH (UPDLOCK, HOLDLOCK) WHERE idSuscripcion = @idSuscripcion) -- BLOQUEA EL REGISTRO A MODIFICAR
            THROW 50002, 'La suscripción indicada no existe.', 1;
 
        IF NOT EXISTS (SELECT 1 FROM VidaU.Universidad WITH (HOLDLOCK) WHERE idUniversidad = @idUniversidad)
            THROW 50007, 'La universidad indicada no existe.', 1;
 
        IF NOT EXISTS (SELECT 1 FROM VidaU.[Plan] WITH (HOLDLOCK) WHERE idPlan = @idPlan)
            THROW 50008, 'El plan indicado no existe.', 1;
 
        UPDATE VidaU.Suscripcion
        SET idUniversidad = @idUniversidad,
            idPlan = @idPlan,
            Estado = @Estado,
            FechaInicio = @FechaInicio,
            FechaFin = @FechaFin
        WHERE idSuscripcion = @idSuscripcion;
 
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO
 
-- Elimina una suscripción. Si otra tabla la referencia, se informa el error.
CREATE OR ALTER PROCEDURE VidaU.sp_Suscripcion_Eliminar
    @idSuscripcion INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
 
        IF NOT EXISTS (SELECT 1 FROM VidaU.Suscripcion WITH (UPDLOCK, HOLDLOCK) WHERE idSuscripcion = @idSuscripcion)
            THROW 50002, 'La suscripción indicada no existe.', 1;
 
        DELETE FROM VidaU.Suscripcion WHERE idSuscripcion = @idSuscripcion;
 
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        DECLARE @Err INT = ERROR_NUMBER();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        IF @Err = 547
            THROW 50003, 'No se puede eliminar la suscripción porque tiene registros relacionados.', 1;
        THROW;
    END CATCH
END
GO
 
-- Consulta una suscripción por id, o todas si @idSuscripcion es NULL.
-- SOLO LECTURA: NO NECESITA TRANSACCION EXPLICITA
CREATE OR ALTER PROCEDURE VidaU.sp_Suscripcion_Consultar
    @idSuscripcion INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT idSuscripcion, idUniversidad, idPlan, Estado, FechaInicio, FechaFin
    FROM VidaU.Suscripcion
    WHERE (@idSuscripcion IS NULL OR idSuscripcion = @idSuscripcion)
    ORDER BY idSuscripcion;
END
GO
 

-- >>>>>> Archivo: Tablas de primer nivel/Usuario_ProcedimientosAlmacenados.sql
/* "Usuario" */
 
-- Agrega un usuario nuevo. Respeta FK_Usuario_Rol y UQ_Usuario_Correo.
-- LA CONTRASENA LLEGA EN TEXTO Y SE GUARDA CON HASHBYTES (NUNCA EN TEXTO PLANO)
CREATE OR ALTER PROCEDURE VidaU.sp_Usuario_Agregar
    @idRol      INT,
    @Nombre     VARCHAR(100),
    @Apellidos  VARCHAR(100),
    @Correo     VARCHAR(150),
    @Contrasena NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        IF @Contrasena IS NULL OR LTRIM(RTRIM(@Contrasena)) = ''
            THROW 50012, 'La contraseña es obligatoria.', 1;
 
        BEGIN TRANSACTION;
 
        IF NOT EXISTS (SELECT 1 FROM VidaU.Rol WITH (HOLDLOCK) WHERE idRol = @idRol) -- VALIDA LA LLAVE FORANEA
            THROW 50011, 'El rol indicado no existe.', 1;
 
        -- UPDLOCK + HOLDLOCK BLOQUEA EL RANGO PARA QUE OTRA SESION NO INSERTE EL MISMO CORREO A LA VEZ
        IF EXISTS (SELECT 1 FROM VidaU.Usuario WITH (UPDLOCK, HOLDLOCK) WHERE Correo = @Correo) -- VALIDA CORREO UNICO
            THROW 50001, 'Ya existe un usuario con ese correo.', 1;
 
        INSERT INTO VidaU.Usuario (idRol, Nombre, Apellidos, Correo, Contrasena)
        VALUES (@idRol, @Nombre, @Apellidos, @Correo, HASHBYTES('SHA2_256', @Contrasena));
 
        DECLARE @idNuevo INT = SCOPE_IDENTITY();
 
        COMMIT TRANSACTION;
        SELECT @idNuevo AS idUsuario;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO
 
-- Actualiza los datos de un usuario existente.
-- SI @Contrasena ES NULL SE CONSERVA LA CONTRASENA ACTUAL; SI SE ENVIA, SE GUARDA SU HASH.
CREATE OR ALTER PROCEDURE VidaU.sp_Usuario_Actualizar
    @idUsuario  INT,
    @idRol      INT,
    @Nombre     VARCHAR(100),
    @Apellidos  VARCHAR(100),
    @Correo     VARCHAR(150),
    @Contrasena NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        IF @Contrasena IS NOT NULL AND LTRIM(RTRIM(@Contrasena)) = ''
            THROW 50012, 'La contraseña no puede estar vacía.', 1;
 
        BEGIN TRANSACTION;
 
        IF NOT EXISTS (SELECT 1 FROM VidaU.Usuario WITH (UPDLOCK, HOLDLOCK) WHERE idUsuario = @idUsuario) -- BLOQUEA EL REGISTRO A MODIFICAR
            THROW 50002, 'El usuario indicado no existe.', 1;
 
        IF NOT EXISTS (SELECT 1 FROM VidaU.Rol WITH (HOLDLOCK) WHERE idRol = @idRol)
            THROW 50011, 'El rol indicado no existe.', 1;
 
        IF EXISTS (SELECT 1 FROM VidaU.Usuario WITH (UPDLOCK, HOLDLOCK) WHERE Correo = @Correo AND idUsuario <> @idUsuario) -- EXCLUYE EL PROPIO REGISTRO
            THROW 50001, 'Ya existe otro usuario con ese correo.', 1;
 
        UPDATE VidaU.Usuario
        SET idRol = @idRol,
            Nombre = @Nombre,
            Apellidos = @Apellidos,
            Correo = @Correo,
            Contrasena = CASE WHEN @Contrasena IS NULL
                              THEN Contrasena -- CONSERVA LA ACTUAL
                              ELSE HASHBYTES('SHA2_256', @Contrasena) END
        WHERE idUsuario = @idUsuario;
 
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO
 
-- Elimina un usuario. Si está referenciado por Estudiante o Bitacora, se informa el error.
CREATE OR ALTER PROCEDURE VidaU.sp_Usuario_Eliminar
    @idUsuario INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
 
        IF NOT EXISTS (SELECT 1 FROM VidaU.Usuario WITH (UPDLOCK, HOLDLOCK) WHERE idUsuario = @idUsuario)
            THROW 50002, 'El usuario indicado no existe.', 1;
 
        DELETE FROM VidaU.Usuario WHERE idUsuario = @idUsuario;
 
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        DECLARE @Err INT = ERROR_NUMBER();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        IF @Err = 547
            THROW 50003, 'No se puede eliminar el usuario porque tiene registros relacionados.', 1;
        THROW;
    END CATCH
END
GO
 
-- Consulta un usuario por id, o todos si @idUsuario es NULL.
-- SOLO LECTURA: NO NECESITA TRANSACCION EXPLICITA
-- NO SE DEVUELVE LA COLUMNA Contrasena (HASH) POR SEGURIDAD
CREATE OR ALTER PROCEDURE VidaU.sp_Usuario_Consultar
    @idUsuario INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT idUsuario, idRol, Nombre, Apellidos, Correo
    FROM VidaU.Usuario
    WHERE (@idUsuario IS NULL OR idUsuario = @idUsuario)
    ORDER BY idUsuario;
END
GO

-- >>>>>> Archivo: Tablas de segundo nivel/Bitacora_ProcedimientosAlmacenados.sql
/* "Bitacora" */
 
-- Agrega un registro de bitácora. Respeta FK_Bitacora_Usuario.
-- SI @FechaHora ES NULL SE USA LA FECHA Y HORA ACTUAL (VALOR POR DEFECTO DE LA TABLA)
CREATE OR ALTER PROCEDURE VidaU.sp_Bitacora_Agregar
    @idUsuario     INT,
    @Accion        VARCHAR(100),
    @TablaAfectada VARCHAR(100),
    @FechaHora     DATETIME = NULL,
    @Descripcion   VARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON; -- ROLLBACK AUTOMATICO ANTE CUALQUIER ERROR DE EJECUCION
    BEGIN TRY
        SET @FechaHora = ISNULL(@FechaHora, GETDATE());
 
        BEGIN TRANSACTION;
 
        IF NOT EXISTS (SELECT 1 FROM VidaU.Usuario WITH (HOLDLOCK) WHERE idUsuario = @idUsuario) -- VALIDA LA LLAVE FORANEA
            THROW 50013, 'El usuario indicado no existe.', 1;
 
        INSERT INTO VidaU.Bitacora (idUsuario, Accion, TablaAfectada, FechaHora, Descripcion)
        VALUES (@idUsuario, @Accion, @TablaAfectada, @FechaHora, @Descripcion);
 
        DECLARE @idNuevo INT = SCOPE_IDENTITY(); -- ID GENERADO POR IDENTITY
 
        COMMIT TRANSACTION;
        SELECT @idNuevo AS idBitacora;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION; -- DESHACE TODO SI ALGO FALLO
        THROW;
    END CATCH
END
GO
 
-- Actualiza un registro de bitácora existente.
-- SI @FechaHora ES NULL SE CONSERVA LA FECHA Y HORA ACTUAL DEL REGISTRO
CREATE OR ALTER PROCEDURE VidaU.sp_Bitacora_Actualizar
    @idBitacora    INT,
    @idUsuario     INT,
    @Accion        VARCHAR(100),
    @TablaAfectada VARCHAR(100),
    @FechaHora     DATETIME = NULL,
    @Descripcion   VARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
 
        IF NOT EXISTS (SELECT 1 FROM VidaU.Bitacora WITH (UPDLOCK, HOLDLOCK) WHERE idBitacora = @idBitacora) -- BLOQUEA EL REGISTRO A MODIFICAR
            THROW 50002, 'El registro de bitácora indicado no existe.', 1;
 
        IF NOT EXISTS (SELECT 1 FROM VidaU.Usuario WITH (HOLDLOCK) WHERE idUsuario = @idUsuario)
            THROW 50013, 'El usuario indicado no existe.', 1;
 
        UPDATE VidaU.Bitacora
        SET idUsuario = @idUsuario,
            Accion = @Accion,
            TablaAfectada = @TablaAfectada,
            FechaHora = ISNULL(@FechaHora, FechaHora), -- CONSERVA LA ACTUAL SI NO SE ENVIA
            Descripcion = @Descripcion
        WHERE idBitacora = @idBitacora;
 
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO
 
-- Elimina un registro de bitácora. Si otra tabla lo referencia, se informa el error.
CREATE OR ALTER PROCEDURE VidaU.sp_Bitacora_Eliminar
    @idBitacora INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
 
        IF NOT EXISTS (SELECT 1 FROM VidaU.Bitacora WITH (UPDLOCK, HOLDLOCK) WHERE idBitacora = @idBitacora)
            THROW 50002, 'El registro de bitácora indicado no existe.', 1;
 
        DELETE FROM VidaU.Bitacora WHERE idBitacora = @idBitacora;
 
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        DECLARE @Err INT = ERROR_NUMBER(); -- SE GUARDA ANTES DEL ROLLBACK
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        IF @Err = 547 -- ERROR DE LLAVE FORANEA
            THROW 50003, 'No se puede eliminar el registro de bitácora porque tiene registros relacionados.', 1;
        THROW;
    END CATCH
END
GO
 
-- Consulta un registro de bitácora por id, o todos si @idBitacora es NULL.
-- SOLO LECTURA: NO NECESITA TRANSACCION EXPLICITA
CREATE OR ALTER PROCEDURE VidaU.sp_Bitacora_Consultar
    @idBitacora INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT idBitacora, idUsuario, Accion, TablaAfectada, FechaHora, Descripcion
    FROM VidaU.Bitacora
    WHERE (@idBitacora IS NULL OR idBitacora = @idBitacora)
    ORDER BY idBitacora;
END
GO

-- >>>>>> Archivo: Tablas de segundo nivel/Estudiante_ProcedimientosAlmacenados.sql
/* "Estudiante" */
 
-- Agrega un estudiante nuevo. Respeta FK_Estudiante_Usuario, UQ_Estudiante_Usuario (1:1 con Usuario),
-- UQ_Estudiante_Carnet y CK_Estudiante_AnnoIngreso (AnnoIngreso >= 2000).
CREATE OR ALTER PROCEDURE VidaU.sp_Estudiante_Agregar
    @idUsuario   INT,
    @Carnet      VARCHAR(20),
    @Carrera     VARCHAR(150),
    @AnnoIngreso INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        IF @AnnoIngreso < 2000 -- VALIDA LA REGLA DEL CHECK ANTES DE ABRIR LA TRANSACCION
            THROW 50014, 'El año de ingreso debe ser mayor o igual a 2000.', 1;
 
        BEGIN TRANSACTION;
 
        IF NOT EXISTS (SELECT 1 FROM VidaU.Usuario WITH (HOLDLOCK) WHERE idUsuario = @idUsuario) -- VALIDA LA LLAVE FORANEA
            THROW 50013, 'El usuario indicado no existe.', 1;
 
        -- UPDLOCK + HOLDLOCK BLOQUEA EL RANGO PARA QUE OTRA SESION NO INSERTE EL MISMO USUARIO O CARNET A LA VEZ
        IF EXISTS (SELECT 1 FROM VidaU.Estudiante WITH (UPDLOCK, HOLDLOCK) WHERE idUsuario = @idUsuario) -- VALIDA RELACION 1:1
            THROW 50018, 'El usuario indicado ya tiene un perfil de estudiante.', 1;
 
        IF EXISTS (SELECT 1 FROM VidaU.Estudiante WITH (UPDLOCK, HOLDLOCK) WHERE Carnet = @Carnet) -- VALIDA CARNET UNICO
            THROW 50001, 'Ya existe un estudiante con ese carnet.', 1;
 
        INSERT INTO VidaU.Estudiante (idUsuario, Carnet, Carrera, AnnoIngreso)
        VALUES (@idUsuario, @Carnet, @Carrera, @AnnoIngreso);
 
        DECLARE @idNuevo INT = SCOPE_IDENTITY();
 
        COMMIT TRANSACTION;
        SELECT @idNuevo AS idEstudiante;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO
 
-- Actualiza los datos de un estudiante existente.
CREATE OR ALTER PROCEDURE VidaU.sp_Estudiante_Actualizar
    @idEstudiante INT,
    @idUsuario    INT,
    @Carnet       VARCHAR(20),
    @Carrera      VARCHAR(150),
    @AnnoIngreso  INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        IF @AnnoIngreso < 2000
            THROW 50014, 'El año de ingreso debe ser mayor o igual a 2000.', 1;
 
        BEGIN TRANSACTION;
 
        IF NOT EXISTS (SELECT 1 FROM VidaU.Estudiante WITH (UPDLOCK, HOLDLOCK) WHERE idEstudiante = @idEstudiante) -- BLOQUEA EL REGISTRO A MODIFICAR
            THROW 50002, 'El estudiante indicado no existe.', 1;
 
        IF NOT EXISTS (SELECT 1 FROM VidaU.Usuario WITH (HOLDLOCK) WHERE idUsuario = @idUsuario)
            THROW 50013, 'El usuario indicado no existe.', 1;
 
        IF EXISTS (SELECT 1 FROM VidaU.Estudiante WITH (UPDLOCK, HOLDLOCK) WHERE idUsuario = @idUsuario AND idEstudiante <> @idEstudiante) -- EXCLUYE EL PROPIO REGISTRO
            THROW 50018, 'El usuario indicado ya tiene un perfil de estudiante.', 1;
 
        IF EXISTS (SELECT 1 FROM VidaU.Estudiante WITH (UPDLOCK, HOLDLOCK) WHERE Carnet = @Carnet AND idEstudiante <> @idEstudiante)
            THROW 50001, 'Ya existe otro estudiante con ese carnet.', 1;
 
        UPDATE VidaU.Estudiante
        SET idUsuario = @idUsuario,
            Carnet = @Carnet,
            Carrera = @Carrera,
            AnnoIngreso = @AnnoIngreso
        WHERE idEstudiante = @idEstudiante;
 
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO
 
-- Elimina un estudiante. Si está en Carrera_Estudiante, Matricula o Resennia, se informa el error.
CREATE OR ALTER PROCEDURE VidaU.sp_Estudiante_Eliminar
    @idEstudiante INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
 
        IF NOT EXISTS (SELECT 1 FROM VidaU.Estudiante WITH (UPDLOCK, HOLDLOCK) WHERE idEstudiante = @idEstudiante)
            THROW 50002, 'El estudiante indicado no existe.', 1;
 
        DELETE FROM VidaU.Estudiante WHERE idEstudiante = @idEstudiante;
 
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        DECLARE @Err INT = ERROR_NUMBER();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        IF @Err = 547
            THROW 50003, 'No se puede eliminar el estudiante porque tiene registros relacionados.', 1;
        THROW;
    END CATCH
END
GO
 
-- Consulta un estudiante por id, o todos si @idEstudiante es NULL.
-- SOLO LECTURA: NO NECESITA TRANSACCION EXPLICITA
CREATE OR ALTER PROCEDURE VidaU.sp_Estudiante_Consultar
    @idEstudiante INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT idEstudiante, idUsuario, Carnet, Carrera, AnnoIngreso
    FROM VidaU.Estudiante
    WHERE (@idEstudiante IS NULL OR idEstudiante = @idEstudiante)
    ORDER BY idEstudiante;
END
GO

-- >>>>>> Archivo: Tablas de segundo nivel/Leccion_ProcedimientosAlmacenados.sql
/* "Leccion" */
 
-- Agrega una lección nueva. Respeta FK_Leccion_Curso, FK_Leccion_Profesor y CK_Leccion_Cupo (Cupo > 0).
CREATE OR ALTER PROCEDURE VidaU.sp_Leccion_Agregar
    @idCurso    INT,
    @idProfesor INT,
    @Horario    VARCHAR(100),
    @Aula       VARCHAR(50) = NULL,
    @Cupo       INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        IF @Cupo <= 0 -- VALIDA LA REGLA DEL CHECK ANTES DE ABRIR LA TRANSACCION
            THROW 50017, 'El cupo debe ser mayor a 0.', 1;
 
        BEGIN TRANSACTION;
 
        IF NOT EXISTS (SELECT 1 FROM VidaU.Curso WITH (HOLDLOCK) WHERE idCurso = @idCurso) -- VALIDA LA LLAVE FORANEA
            THROW 50015, 'El curso indicado no existe.', 1;
 
        IF NOT EXISTS (SELECT 1 FROM VidaU.Profesor WITH (HOLDLOCK) WHERE idProfesor = @idProfesor)
            THROW 50016, 'El profesor indicado no existe.', 1;
 
        INSERT INTO VidaU.Leccion (idCurso, idProfesor, Horario, Aula, Cupo)
        VALUES (@idCurso, @idProfesor, @Horario, @Aula, @Cupo);
 
        DECLARE @idNuevo INT = SCOPE_IDENTITY();
 
        COMMIT TRANSACTION;
        SELECT @idNuevo AS idLeccion;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO
 
-- Actualiza los datos de una lección existente.
CREATE OR ALTER PROCEDURE VidaU.sp_Leccion_Actualizar
    @idLeccion  INT,
    @idCurso    INT,
    @idProfesor INT,
    @Horario    VARCHAR(100),
    @Aula       VARCHAR(50) = NULL,
    @Cupo       INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        IF @Cupo <= 0
            THROW 50017, 'El cupo debe ser mayor a 0.', 1;
 
        BEGIN TRANSACTION;
 
        IF NOT EXISTS (SELECT 1 FROM VidaU.Leccion WITH (UPDLOCK, HOLDLOCK) WHERE idLeccion = @idLeccion) -- BLOQUEA EL REGISTRO A MODIFICAR
            THROW 50002, 'La lección indicada no existe.', 1;
 
        IF NOT EXISTS (SELECT 1 FROM VidaU.Curso WITH (HOLDLOCK) WHERE idCurso = @idCurso)
            THROW 50015, 'El curso indicado no existe.', 1;
 
        IF NOT EXISTS (SELECT 1 FROM VidaU.Profesor WITH (HOLDLOCK) WHERE idProfesor = @idProfesor)
            THROW 50016, 'El profesor indicado no existe.', 1;
 
        UPDATE VidaU.Leccion
        SET idCurso = @idCurso,
            idProfesor = @idProfesor,
            Horario = @Horario,
            Aula = @Aula,
            Cupo = @Cupo
        WHERE idLeccion = @idLeccion;
 
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO
 
-- Elimina una lección. Si está referenciada por Resennia u otras tablas, se informa el error.
CREATE OR ALTER PROCEDURE VidaU.sp_Leccion_Eliminar
    @idLeccion INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
 
        IF NOT EXISTS (SELECT 1 FROM VidaU.Leccion WITH (UPDLOCK, HOLDLOCK) WHERE idLeccion = @idLeccion)
            THROW 50002, 'La lección indicada no existe.', 1;
 
        DELETE FROM VidaU.Leccion WHERE idLeccion = @idLeccion;
 
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        DECLARE @Err INT = ERROR_NUMBER();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        IF @Err = 547
            THROW 50003, 'No se puede eliminar la lección porque tiene registros relacionados.', 1;
        THROW;
    END CATCH
END
GO
 
-- Consulta una lección por id, o todas si @idLeccion es NULL.
-- SOLO LECTURA: NO NECESITA TRANSACCION EXPLICITA
CREATE OR ALTER PROCEDURE VidaU.sp_Leccion_Consultar
    @idLeccion INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT idLeccion, idCurso, idProfesor, Horario, Aula, Cupo
    FROM VidaU.Leccion
    WHERE (@idLeccion IS NULL OR idLeccion = @idLeccion)
    ORDER BY idLeccion;
END
GO

-- >>>>>> Archivo: Tablas puente/Universidad_Profesor_ProcedimientosAlmacenados.sql
/* "Universidad_Profesor" */
 
-- Agrega la relación entre una universidad y un profesor. Respeta FK_UnivProf_Universidad,
-- FK_UnivProf_Profesor y PK_Universidad_Profesor (la misma pareja no se repite).
CREATE OR ALTER PROCEDURE VidaU.sp_Universidad_Profesor_Agregar
    @idUniversidad INT,
    @idProfesor    INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON; -- ROLLBACK AUTOMATICO ANTE CUALQUIER ERROR DE EJECUCION
    BEGIN TRY
        BEGIN TRANSACTION;
 
        IF NOT EXISTS (SELECT 1 FROM VidaU.Universidad WITH (HOLDLOCK) WHERE idUniversidad = @idUniversidad) -- VALIDA LAS LLAVES FORANEAS
            THROW 50007, 'La universidad indicada no existe.', 1;
 
        IF NOT EXISTS (SELECT 1 FROM VidaU.Profesor WITH (HOLDLOCK) WHERE idProfesor = @idProfesor)
            THROW 50016, 'El profesor indicado no existe.', 1;
 
        IF EXISTS (SELECT 1 FROM VidaU.Universidad_Profesor WITH (UPDLOCK, HOLDLOCK)
                   WHERE idUniversidad = @idUniversidad AND idProfesor = @idProfesor) -- VALIDA QUE LA PAREJA NO EXISTA
            THROW 50001, 'El profesor ya está asociado a esa universidad.', 1;
 
        INSERT INTO VidaU.Universidad_Profesor (idUniversidad, idProfesor)
        VALUES (@idUniversidad, @idProfesor);
 
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION; -- DESHACE TODO SI ALGO FALLO
        THROW;
    END CATCH
END
GO
 
-- Cambia una pareja universidad-profesor existente por otra pareja.
CREATE OR ALTER PROCEDURE VidaU.sp_Universidad_Profesor_Actualizar
    @idUniversidadAnterior INT,
    @idProfesorAnterior    INT,
    @idUniversidadNueva    INT,
    @idProfesorNuevo       INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
 
        IF NOT EXISTS (SELECT 1 FROM VidaU.Universidad_Profesor WITH (UPDLOCK, HOLDLOCK)
                       WHERE idUniversidad = @idUniversidadAnterior AND idProfesor = @idProfesorAnterior) -- BLOQUEA LA PAREJA A MODIFICAR
            THROW 50002, 'La relación indicada no existe.', 1;
 
        IF NOT EXISTS (SELECT 1 FROM VidaU.Universidad WITH (HOLDLOCK) WHERE idUniversidad = @idUniversidadNueva)
            THROW 50007, 'La universidad indicada no existe.', 1;
 
        IF NOT EXISTS (SELECT 1 FROM VidaU.Profesor WITH (HOLDLOCK) WHERE idProfesor = @idProfesorNuevo)
            THROW 50016, 'El profesor indicado no existe.', 1;
 
        IF (@idUniversidadNueva <> @idUniversidadAnterior OR @idProfesorNuevo <> @idProfesorAnterior) -- SOLO SI LA PAREJA CAMBIA
           AND EXISTS (SELECT 1 FROM VidaU.Universidad_Profesor WITH (UPDLOCK, HOLDLOCK)
                       WHERE idUniversidad = @idUniversidadNueva AND idProfesor = @idProfesorNuevo)
            THROW 50001, 'El profesor ya está asociado a esa universidad.', 1;
 
        UPDATE VidaU.Universidad_Profesor
        SET idUniversidad = @idUniversidadNueva,
            idProfesor = @idProfesorNuevo
        WHERE idUniversidad = @idUniversidadAnterior AND idProfesor = @idProfesorAnterior;
 
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO
 
-- Elimina la relación entre una universidad y un profesor.
CREATE OR ALTER PROCEDURE VidaU.sp_Universidad_Profesor_Eliminar
    @idUniversidad INT,
    @idProfesor    INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
 
        IF NOT EXISTS (SELECT 1 FROM VidaU.Universidad_Profesor WITH (UPDLOCK, HOLDLOCK)
                       WHERE idUniversidad = @idUniversidad AND idProfesor = @idProfesor)
            THROW 50002, 'La relación indicada no existe.', 1;
 
        DELETE FROM VidaU.Universidad_Profesor
        WHERE idUniversidad = @idUniversidad AND idProfesor = @idProfesor;
 
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        DECLARE @Err INT = ERROR_NUMBER(); -- SE GUARDA ANTES DEL ROLLBACK
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        IF @Err = 547 -- ERROR DE LLAVE FORANEA
            THROW 50003, 'No se puede eliminar la relación porque tiene registros relacionados.', 1;
        THROW;
    END CATCH
END
GO
 
-- Consulta las relaciones universidad-profesor. Cada parámetro en NULL no filtra.
-- SOLO LECTURA: NO NECESITA TRANSACCION EXPLICITA
CREATE OR ALTER PROCEDURE VidaU.sp_Universidad_Profesor_Consultar
    @idUniversidad INT = NULL,
    @idProfesor    INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT idUniversidad, idProfesor
    FROM VidaU.Universidad_Profesor
    WHERE (@idUniversidad IS NULL OR idUniversidad = @idUniversidad)
      AND (@idProfesor IS NULL OR idProfesor = @idProfesor)
    ORDER BY idUniversidad, idProfesor;
END
GO

-- >>>>>> Archivo: Tablas puente/Sede_Carrera_ProcedimientosAlmacenados.sql
/* "Sede_Carrera" */
 
-- Agrega la relación entre una sede y una carrera. Respeta FK_SedeCarr_Sede,
-- FK_SedeCarr_Carrera y PK_Sede_Carrera (la misma pareja no se repite).
CREATE OR ALTER PROCEDURE VidaU.sp_Sede_Carrera_Agregar
    @idSede    INT,
    @idCarrera INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
 
        IF NOT EXISTS (SELECT 1 FROM VidaU.Sede WITH (HOLDLOCK) WHERE idSede = @idSede)
            THROW 50019, 'La sede indicada no existe.', 1;
 
        IF NOT EXISTS (SELECT 1 FROM VidaU.Carrera WITH (HOLDLOCK) WHERE idCarrera = @idCarrera)
            THROW 50020, 'La carrera indicada no existe.', 1;
 
        IF EXISTS (SELECT 1 FROM VidaU.Sede_Carrera WITH (UPDLOCK, HOLDLOCK)
                   WHERE idSede = @idSede AND idCarrera = @idCarrera)
            THROW 50001, 'La carrera ya está asociada a esa sede.', 1;
 
        INSERT INTO VidaU.Sede_Carrera (idSede, idCarrera)
        VALUES (@idSede, @idCarrera);
 
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO
 
-- Cambia una pareja sede-carrera existente por otra pareja.
CREATE OR ALTER PROCEDURE VidaU.sp_Sede_Carrera_Actualizar
    @idSedeAnterior    INT,
    @idCarreraAnterior INT,
    @idSedeNueva       INT,
    @idCarreraNueva    INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
 
        IF NOT EXISTS (SELECT 1 FROM VidaU.Sede_Carrera WITH (UPDLOCK, HOLDLOCK)
                       WHERE idSede = @idSedeAnterior AND idCarrera = @idCarreraAnterior)
            THROW 50002, 'La relación indicada no existe.', 1;
 
        IF NOT EXISTS (SELECT 1 FROM VidaU.Sede WITH (HOLDLOCK) WHERE idSede = @idSedeNueva)
            THROW 50019, 'La sede indicada no existe.', 1;
 
        IF NOT EXISTS (SELECT 1 FROM VidaU.Carrera WITH (HOLDLOCK) WHERE idCarrera = @idCarreraNueva)
            THROW 50020, 'La carrera indicada no existe.', 1;
 
        IF (@idSedeNueva <> @idSedeAnterior OR @idCarreraNueva <> @idCarreraAnterior)
           AND EXISTS (SELECT 1 FROM VidaU.Sede_Carrera WITH (UPDLOCK, HOLDLOCK)
                       WHERE idSede = @idSedeNueva AND idCarrera = @idCarreraNueva)
            THROW 50001, 'La carrera ya está asociada a esa sede.', 1;
 
        UPDATE VidaU.Sede_Carrera
        SET idSede = @idSedeNueva,
            idCarrera = @idCarreraNueva
        WHERE idSede = @idSedeAnterior AND idCarrera = @idCarreraAnterior;
 
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO
 
-- Elimina la relación entre una sede y una carrera.
CREATE OR ALTER PROCEDURE VidaU.sp_Sede_Carrera_Eliminar
    @idSede    INT,
    @idCarrera INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
 
        IF NOT EXISTS (SELECT 1 FROM VidaU.Sede_Carrera WITH (UPDLOCK, HOLDLOCK)
                       WHERE idSede = @idSede AND idCarrera = @idCarrera)
            THROW 50002, 'La relación indicada no existe.', 1;
 
        DELETE FROM VidaU.Sede_Carrera
        WHERE idSede = @idSede AND idCarrera = @idCarrera;
 
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        DECLARE @Err INT = ERROR_NUMBER();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        IF @Err = 547
            THROW 50003, 'No se puede eliminar la relación porque tiene registros relacionados.', 1;
        THROW;
    END CATCH
END
GO
 
-- Consulta las relaciones sede-carrera. Cada parámetro en NULL no filtra.
-- SOLO LECTURA: NO NECESITA TRANSACCION EXPLICITA
CREATE OR ALTER PROCEDURE VidaU.sp_Sede_Carrera_Consultar
    @idSede    INT = NULL,
    @idCarrera INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT idSede, idCarrera
    FROM VidaU.Sede_Carrera
    WHERE (@idSede IS NULL OR idSede = @idSede)
      AND (@idCarrera IS NULL OR idCarrera = @idCarrera)
    ORDER BY idSede, idCarrera;
END
GO

-- >>>>>> Archivo: Tablas puente/Carrera_Curso_ProcedimientosAlmacenados.sql
/* "Carrera_Curso" */
 
-- Agrega la relación entre una carrera y un curso. Respeta FK_CarrCurso_Carrera,
-- FK_CarrCurso_Curso y PK_Carrera_Curso (la misma pareja no se repite).
CREATE OR ALTER PROCEDURE VidaU.sp_Carrera_Curso_Agregar
    @idCarrera INT,
    @idCurso   INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
 
        IF NOT EXISTS (SELECT 1 FROM VidaU.Carrera WITH (HOLDLOCK) WHERE idCarrera = @idCarrera)
            THROW 50020, 'La carrera indicada no existe.', 1;
 
        IF NOT EXISTS (SELECT 1 FROM VidaU.Curso WITH (HOLDLOCK) WHERE idCurso = @idCurso)
            THROW 50015, 'El curso indicado no existe.', 1;
 
        IF EXISTS (SELECT 1 FROM VidaU.Carrera_Curso WITH (UPDLOCK, HOLDLOCK)
                   WHERE idCarrera = @idCarrera AND idCurso = @idCurso)
            THROW 50001, 'El curso ya está asociado a esa carrera.', 1;
 
        INSERT INTO VidaU.Carrera_Curso (idCarrera, idCurso)
        VALUES (@idCarrera, @idCurso);
 
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO
 
-- Cambia una pareja carrera-curso existente por otra pareja.
CREATE OR ALTER PROCEDURE VidaU.sp_Carrera_Curso_Actualizar
    @idCarreraAnterior INT,
    @idCursoAnterior   INT,
    @idCarreraNueva    INT,
    @idCursoNuevo      INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
 
        IF NOT EXISTS (SELECT 1 FROM VidaU.Carrera_Curso WITH (UPDLOCK, HOLDLOCK)
                       WHERE idCarrera = @idCarreraAnterior AND idCurso = @idCursoAnterior)
            THROW 50002, 'La relación indicada no existe.', 1;
 
        IF NOT EXISTS (SELECT 1 FROM VidaU.Carrera WITH (HOLDLOCK) WHERE idCarrera = @idCarreraNueva)
            THROW 50020, 'La carrera indicada no existe.', 1;
 
        IF NOT EXISTS (SELECT 1 FROM VidaU.Curso WITH (HOLDLOCK) WHERE idCurso = @idCursoNuevo)
            THROW 50015, 'El curso indicado no existe.', 1;
 
        IF (@idCarreraNueva <> @idCarreraAnterior OR @idCursoNuevo <> @idCursoAnterior)
           AND EXISTS (SELECT 1 FROM VidaU.Carrera_Curso WITH (UPDLOCK, HOLDLOCK)
                       WHERE idCarrera = @idCarreraNueva AND idCurso = @idCursoNuevo)
            THROW 50001, 'El curso ya está asociado a esa carrera.', 1;
 
        UPDATE VidaU.Carrera_Curso
        SET idCarrera = @idCarreraNueva,
            idCurso = @idCursoNuevo
        WHERE idCarrera = @idCarreraAnterior AND idCurso = @idCursoAnterior;
 
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO
 
-- Elimina la relación entre una carrera y un curso.
CREATE OR ALTER PROCEDURE VidaU.sp_Carrera_Curso_Eliminar
    @idCarrera INT,
    @idCurso   INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
 
        IF NOT EXISTS (SELECT 1 FROM VidaU.Carrera_Curso WITH (UPDLOCK, HOLDLOCK)
                       WHERE idCarrera = @idCarrera AND idCurso = @idCurso)
            THROW 50002, 'La relación indicada no existe.', 1;
 
        DELETE FROM VidaU.Carrera_Curso
        WHERE idCarrera = @idCarrera AND idCurso = @idCurso;
 
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        DECLARE @Err INT = ERROR_NUMBER();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        IF @Err = 547
            THROW 50003, 'No se puede eliminar la relación porque tiene registros relacionados.', 1;
        THROW;
    END CATCH
END
GO
 
-- Consulta las relaciones carrera-curso. Cada parámetro en NULL no filtra.
-- SOLO LECTURA: NO NECESITA TRANSACCION EXPLICITA
CREATE OR ALTER PROCEDURE VidaU.sp_Carrera_Curso_Consultar
    @idCarrera INT = NULL,
    @idCurso   INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT idCarrera, idCurso
    FROM VidaU.Carrera_Curso
    WHERE (@idCarrera IS NULL OR idCarrera = @idCarrera)
      AND (@idCurso IS NULL OR idCurso = @idCurso)
    ORDER BY idCarrera, idCurso;
END
GO

-- >>>>>> Archivo: Tablas puente/Carrera_Estudiante_ProcedimientosAlmacenados.sql
/* "Carrera_Estudiante" */
 
-- Agrega la relación entre una carrera y un estudiante. Respeta FK_CarrEst_Carrera,
-- FK_CarrEst_Estudiante y PK_Carrera_Estudiante (la misma pareja no se repite).
CREATE OR ALTER PROCEDURE VidaU.sp_Carrera_Estudiante_Agregar
    @idCarrera    INT,
    @idEstudiante INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
 
        IF NOT EXISTS (SELECT 1 FROM VidaU.Carrera WITH (HOLDLOCK) WHERE idCarrera = @idCarrera)
            THROW 50020, 'La carrera indicada no existe.', 1;
 
        IF NOT EXISTS (SELECT 1 FROM VidaU.Estudiante WITH (HOLDLOCK) WHERE idEstudiante = @idEstudiante)
            THROW 50021, 'El estudiante indicado no existe.', 1;
 
        IF EXISTS (SELECT 1 FROM VidaU.Carrera_Estudiante WITH (UPDLOCK, HOLDLOCK)
                   WHERE idCarrera = @idCarrera AND idEstudiante = @idEstudiante)
            THROW 50001, 'El estudiante ya está asociado a esa carrera.', 1;
 
        INSERT INTO VidaU.Carrera_Estudiante (idCarrera, idEstudiante)
        VALUES (@idCarrera, @idEstudiante);
 
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO
 
-- Cambia una pareja carrera-estudiante existente por otra pareja.
CREATE OR ALTER PROCEDURE VidaU.sp_Carrera_Estudiante_Actualizar
    @idCarreraAnterior    INT,
    @idEstudianteAnterior INT,
    @idCarreraNueva       INT,
    @idEstudianteNuevo    INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
 
        IF NOT EXISTS (SELECT 1 FROM VidaU.Carrera_Estudiante WITH (UPDLOCK, HOLDLOCK)
                       WHERE idCarrera = @idCarreraAnterior AND idEstudiante = @idEstudianteAnterior)
            THROW 50002, 'La relación indicada no existe.', 1;
 
        IF NOT EXISTS (SELECT 1 FROM VidaU.Carrera WITH (HOLDLOCK) WHERE idCarrera = @idCarreraNueva)
            THROW 50020, 'La carrera indicada no existe.', 1;
 
        IF NOT EXISTS (SELECT 1 FROM VidaU.Estudiante WITH (HOLDLOCK) WHERE idEstudiante = @idEstudianteNuevo)
            THROW 50021, 'El estudiante indicado no existe.', 1;
 
        IF (@idCarreraNueva <> @idCarreraAnterior OR @idEstudianteNuevo <> @idEstudianteAnterior)
           AND EXISTS (SELECT 1 FROM VidaU.Carrera_Estudiante WITH (UPDLOCK, HOLDLOCK)
                       WHERE idCarrera = @idCarreraNueva AND idEstudiante = @idEstudianteNuevo)
            THROW 50001, 'El estudiante ya está asociado a esa carrera.', 1;
 
        UPDATE VidaU.Carrera_Estudiante
        SET idCarrera = @idCarreraNueva,
            idEstudiante = @idEstudianteNuevo
        WHERE idCarrera = @idCarreraAnterior AND idEstudiante = @idEstudianteAnterior;
 
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO
 
-- Elimina la relación entre una carrera y un estudiante.
CREATE OR ALTER PROCEDURE VidaU.sp_Carrera_Estudiante_Eliminar
    @idCarrera    INT,
    @idEstudiante INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
 
        IF NOT EXISTS (SELECT 1 FROM VidaU.Carrera_Estudiante WITH (UPDLOCK, HOLDLOCK)
                       WHERE idCarrera = @idCarrera AND idEstudiante = @idEstudiante)
            THROW 50002, 'La relación indicada no existe.', 1;
 
        DELETE FROM VidaU.Carrera_Estudiante
        WHERE idCarrera = @idCarrera AND idEstudiante = @idEstudiante;
 
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        DECLARE @Err INT = ERROR_NUMBER();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        IF @Err = 547
            THROW 50003, 'No se puede eliminar la relación porque tiene registros relacionados.', 1;
        THROW;
    END CATCH
END
GO
 
-- Consulta las relaciones carrera-estudiante. Cada parámetro en NULL no filtra.
-- SOLO LECTURA: NO NECESITA TRANSACCION EXPLICITA
CREATE OR ALTER PROCEDURE VidaU.sp_Carrera_Estudiante_Consultar
    @idCarrera    INT = NULL,
    @idEstudiante INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT idCarrera, idEstudiante
    FROM VidaU.Carrera_Estudiante
    WHERE (@idCarrera IS NULL OR idCarrera = @idCarrera)
      AND (@idEstudiante IS NULL OR idEstudiante = @idEstudiante)
    ORDER BY idCarrera, idEstudiante;
END
GO

-- >>>>>> Archivo: Tablas de tercer nivel/Matricula_ProcedimientosAlmacenados.sql
/* "Matricula" */
 
-- Agrega una matrícula nueva. Respeta FK_Matricula_Estudiante y CK_Matricula_Estado.
-- SI @FechaMatricula ES NULL SE USA LA FECHA ACTUAL (SOLO FECHA, SIN HORA)
-- SI @Estado ES NULL SE USA EL VALOR POR DEFECTO 'Matriculado'
CREATE OR ALTER PROCEDURE VidaU.sp_Matricula_Agregar
    @idEstudiante   INT,
    @FechaMatricula DATE = NULL,
    @Estado         VARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON; -- ROLLBACK AUTOMATICO ANTE CUALQUIER ERROR DE EJECUCION
    BEGIN TRY
        SET @FechaMatricula = ISNULL(@FechaMatricula, CAST(GETDATE() AS DATE));
        SET @Estado = ISNULL(@Estado, 'Matriculado');
 
        IF @Estado NOT IN ('Matriculado','Retirado','Finalizado') -- VALIDA LA REGLA DEL CHECK ANTES DE ABRIR LA TRANSACCION
            THROW 50024, 'El estado debe ser Matriculado, Retirado o Finalizado.', 1;
 
        BEGIN TRANSACTION;
 
        IF NOT EXISTS (SELECT 1 FROM VidaU.Estudiante WITH (HOLDLOCK) WHERE idEstudiante = @idEstudiante) -- VALIDA LA LLAVE FORANEA
            THROW 50021, 'El estudiante indicado no existe.', 1;
 
        INSERT INTO VidaU.Matricula (idEstudiante, FechaMatricula, Estado)
        VALUES (@idEstudiante, @FechaMatricula, @Estado);
 
        DECLARE @idNuevo INT = SCOPE_IDENTITY(); -- ID GENERADO POR IDENTITY
 
        COMMIT TRANSACTION;
        SELECT @idNuevo AS idMatricula;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION; -- DESHACE TODO SI ALGO FALLO
        THROW;
    END CATCH
END
GO
 
-- Actualiza los datos de una matrícula existente.
-- SI @FechaMatricula ES NULL SE CONSERVA LA FECHA ACTUAL DEL REGISTRO
CREATE OR ALTER PROCEDURE VidaU.sp_Matricula_Actualizar
    @idMatricula    INT,
    @idEstudiante   INT,
    @FechaMatricula DATE = NULL,
    @Estado         VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        IF @Estado NOT IN ('Matriculado','Retirado','Finalizado')
            THROW 50024, 'El estado debe ser Matriculado, Retirado o Finalizado.', 1;
 
        BEGIN TRANSACTION;
 
        IF NOT EXISTS (SELECT 1 FROM VidaU.Matricula WITH (UPDLOCK, HOLDLOCK) WHERE idMatricula = @idMatricula) -- BLOQUEA EL REGISTRO A MODIFICAR
            THROW 50002, 'La matrícula indicada no existe.', 1;
 
        IF NOT EXISTS (SELECT 1 FROM VidaU.Estudiante WITH (HOLDLOCK) WHERE idEstudiante = @idEstudiante)
            THROW 50021, 'El estudiante indicado no existe.', 1;
 
        UPDATE VidaU.Matricula
        SET idEstudiante = @idEstudiante,
            FechaMatricula = ISNULL(@FechaMatricula, FechaMatricula), -- CONSERVA LA ACTUAL SI NO SE ENVIA
            Estado = @Estado
        WHERE idMatricula = @idMatricula;
 
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO
 
-- Elimina una matrícula. Si otra tabla la referencia, se informa el error.
CREATE OR ALTER PROCEDURE VidaU.sp_Matricula_Eliminar
    @idMatricula INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
 
        IF NOT EXISTS (SELECT 1 FROM VidaU.Matricula WITH (UPDLOCK, HOLDLOCK) WHERE idMatricula = @idMatricula)
            THROW 50002, 'La matrícula indicada no existe.', 1;
 
        DELETE FROM VidaU.Matricula WHERE idMatricula = @idMatricula;
 
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        DECLARE @Err INT = ERROR_NUMBER(); -- SE GUARDA ANTES DEL ROLLBACK
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        IF @Err = 547 -- ERROR DE LLAVE FORANEA
            THROW 50003, 'No se puede eliminar la matrícula porque tiene registros relacionados.', 1;
        THROW;
    END CATCH
END
GO
 
-- Consulta una matrícula por id, o todas si @idMatricula es NULL.
-- SOLO LECTURA: NO NECESITA TRANSACCION EXPLICITA
CREATE OR ALTER PROCEDURE VidaU.sp_Matricula_Consultar
    @idMatricula INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT idMatricula, idEstudiante, FechaMatricula, Estado
    FROM VidaU.Matricula
    WHERE (@idMatricula IS NULL OR idMatricula = @idMatricula)
    ORDER BY idMatricula;
END
GO

-- >>>>>> Archivo: Tablas de tercer nivel/Resennia_ProcedimientosAlmacenados.sql
/* "Resennia" */
 
-- Agrega una reseña nueva. Respeta FK_Resennia_Leccion, FK_Resennia_Estudiante,
-- UQ_Resennia_Estudiante_Leccion (una reseña por estudiante por lección) y CK_Resennia_Estado.
-- NombreCurso Y NombreProfesor NO LOS ENVIA EL USUARIO: SE COPIAN DESDE LA LECCION EN ESTE MOMENTO.
-- SI @Estado ES NULL SE USA 'EnRevision'; SI @EsAnonima ES NULL SE USA 1 (ANONIMA);
-- SI @FechaResennia ES NULL SE USA LA FECHA Y HORA ACTUAL
CREATE OR ALTER PROCEDURE VidaU.sp_Resennia_Agregar
    @idLeccion      INT,
    @idEstudiante   INT,
    @Estado         VARCHAR(20) = NULL,
    @EsAnonima      BIT = NULL,
    @FechaResennia  DATETIME = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
 
    DECLARE @NombreCurso    VARCHAR(150);
    DECLARE @NombreProfesor VARCHAR(200);
 
    BEGIN TRY
        SET @Estado = ISNULL(@Estado, 'EnRevision');
        SET @EsAnonima = ISNULL(@EsAnonima, 1);
        SET @FechaResennia = ISNULL(@FechaResennia, GETDATE());
 
        IF @Estado NOT IN ('Visible','Oculta','EnRevision') -- VALIDA LA REGLA DEL CHECK ANTES DE ABRIR LA TRANSACCION
            THROW 50025, 'El estado debe ser Visible, Oculta o EnRevision.', 1;
 
        BEGIN TRANSACTION;
 
        IF NOT EXISTS (SELECT 1 FROM VidaU.Estudiante WITH (HOLDLOCK) WHERE idEstudiante = @idEstudiante) -- VALIDA LAS LLAVES FORANEAS
            THROW 50021, 'El estudiante indicado no existe.', 1;
 
        -- OBTIENE LOS NOMBRES DESDE LA LECCION Y BLOQUEA LOS REGISTROS DURANTE LA TRANSACCION
        SELECT @NombreCurso = c.Nombre,
               @NombreProfesor = LEFT(p.Nombre + ' ' + p.Apellido, 200)
        FROM VidaU.Leccion l WITH (HOLDLOCK)
        INNER JOIN VidaU.Curso c WITH (HOLDLOCK) ON c.idCurso = l.idCurso
        INNER JOIN VidaU.Profesor p WITH (HOLDLOCK) ON p.idProfesor = l.idProfesor
        WHERE l.idLeccion = @idLeccion;
 
        IF @NombreCurso IS NULL -- NO SE ENCONTRO LA LECCION
            THROW 50022, 'La lección indicada no existe.', 1;
 
        -- UPDLOCK + HOLDLOCK BLOQUEA EL RANGO PARA QUE OTRA SESION NO INSERTE LA MISMA RESENNIA A LA VEZ
        IF EXISTS (SELECT 1 FROM VidaU.Resennia WITH (UPDLOCK, HOLDLOCK)
                   WHERE idEstudiante = @idEstudiante AND idLeccion = @idLeccion) -- VALIDA UNA RESENNIA POR ESTUDIANTE POR LECCION
            THROW 50023, 'El estudiante ya dejó una reseña para esa lección.', 1;
 
        INSERT INTO VidaU.Resennia (idLeccion, idEstudiante, Estado, EsAnonima, NombreCurso, FechaResennia, NombreProfesor)
        VALUES (@idLeccion, @idEstudiante, @Estado, @EsAnonima, @NombreCurso, @FechaResennia, @NombreProfesor);
 
        DECLARE @idNuevo INT = SCOPE_IDENTITY();
 
        COMMIT TRANSACTION;
        SELECT @idNuevo AS idResennia;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO
 
-- Actualiza los datos de una reseña existente.
-- NombreCurso Y NombreProfesor SON COPIAS DEL MOMENTO DE LA RESENNIA: SOLO SE VUELVEN A COPIAR
-- DESDE LA LECCION SI CAMBIA @idLeccion; SI NO, SE CONSERVAN.
-- SI @FechaResennia ES NULL SE CONSERVA LA FECHA ACTUAL DEL REGISTRO
CREATE OR ALTER PROCEDURE VidaU.sp_Resennia_Actualizar
    @idResennia     INT,
    @idLeccion      INT,
    @idEstudiante   INT,
    @Estado         VARCHAR(20),
    @EsAnonima      BIT,
    @FechaResennia  DATETIME = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
 
    DECLARE @idLeccionActual INT;
    DECLARE @NombreCurso     VARCHAR(150);
    DECLARE @NombreProfesor  VARCHAR(200);
 
    BEGIN TRY
        IF @Estado NOT IN ('Visible','Oculta','EnRevision')
            THROW 50025, 'El estado debe ser Visible, Oculta o EnRevision.', 1;
 
        BEGIN TRANSACTION;
 
        -- BLOQUEA EL REGISTRO A MODIFICAR Y GUARDA SU LECCION ACTUAL
        SELECT @idLeccionActual = idLeccion
        FROM VidaU.Resennia WITH (UPDLOCK, HOLDLOCK)
        WHERE idResennia = @idResennia;
 
        IF @idLeccionActual IS NULL
            THROW 50002, 'La reseña indicada no existe.', 1;
 
        IF NOT EXISTS (SELECT 1 FROM VidaU.Estudiante WITH (HOLDLOCK) WHERE idEstudiante = @idEstudiante)
            THROW 50021, 'El estudiante indicado no existe.', 1;
 
        SELECT @NombreCurso = c.Nombre,
               @NombreProfesor = LEFT(p.Nombre + ' ' + p.Apellido, 200)
        FROM VidaU.Leccion l WITH (HOLDLOCK)
        INNER JOIN VidaU.Curso c WITH (HOLDLOCK) ON c.idCurso = l.idCurso
        INNER JOIN VidaU.Profesor p WITH (HOLDLOCK) ON p.idProfesor = l.idProfesor
        WHERE l.idLeccion = @idLeccion;
 
        IF @NombreCurso IS NULL
            THROW 50022, 'La lección indicada no existe.', 1;
 
        IF EXISTS (SELECT 1 FROM VidaU.Resennia WITH (UPDLOCK, HOLDLOCK)
                   WHERE idEstudiante = @idEstudiante AND idLeccion = @idLeccion AND idResennia <> @idResennia) -- EXCLUYE EL PROPIO REGISTRO
            THROW 50023, 'El estudiante ya dejó una reseña para esa lección.', 1;
 
        UPDATE VidaU.Resennia
        SET idLeccion = @idLeccion,
            idEstudiante = @idEstudiante,
            Estado = @Estado,
            EsAnonima = @EsAnonima,
            NombreCurso = CASE WHEN @idLeccion = @idLeccionActual THEN NombreCurso ELSE @NombreCurso END, -- CONSERVA LA COPIA SI LA LECCION NO CAMBIA
            NombreProfesor = CASE WHEN @idLeccion = @idLeccionActual THEN NombreProfesor ELSE @NombreProfesor END,
            FechaResennia = ISNULL(@FechaResennia, FechaResennia) -- CONSERVA LA ACTUAL SI NO SE ENVIA
        WHERE idResennia = @idResennia;
 
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO
 
-- Elimina una reseña. Si tiene evaluaciones relacionadas (tabla Evaluacion), se informa el error.
CREATE OR ALTER PROCEDURE VidaU.sp_Resennia_Eliminar
    @idResennia INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
 
        IF NOT EXISTS (SELECT 1 FROM VidaU.Resennia WITH (UPDLOCK, HOLDLOCK) WHERE idResennia = @idResennia)
            THROW 50002, 'La reseña indicada no existe.', 1;
 
        DELETE FROM VidaU.Resennia WHERE idResennia = @idResennia;
 
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        DECLARE @Err INT = ERROR_NUMBER();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        IF @Err = 547
            THROW 50003, 'No se puede eliminar la reseña porque tiene registros relacionados.', 1;
        THROW;
    END CATCH
END
GO
 
-- Consulta una reseña por id, o todas si @idResennia es NULL.
-- SOLO LECTURA: NO NECESITA TRANSACCION EXPLICITA
CREATE OR ALTER PROCEDURE VidaU.sp_Resennia_Consultar
    @idResennia INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT idResennia, idLeccion, idEstudiante, Estado, EsAnonima,
           NombreCurso, NombreProfesor, FechaResennia
    FROM VidaU.Resennia
    WHERE (@idResennia IS NULL OR idResennia = @idResennia)
    ORDER BY idResennia;
END
GO

-- >>>>>> Archivo: Tablas de cuarto nivel/Evaluacion_ProcedimientosAlmacenados.sql
/* "Evaluacion" */
 
-- Agrega una evaluación nueva a una reseña. Respeta FK_Evaluacion_Resennia y
-- CK_Evaluacion_Calificacion (Calificacion entre 1 y 5).
CREATE OR ALTER PROCEDURE VidaU.sp_Evaluacion_Agregar
    @idResennia   INT,
    @Calificacion DECIMAL(2,1),
    @Comentario   VARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON; -- ROLLBACK AUTOMATICO ANTE CUALQUIER ERROR DE EJECUCION
    BEGIN TRY
        IF @Calificacion IS NULL OR @Calificacion NOT BETWEEN 1 AND 5 -- VALIDA LA REGLA DEL CHECK ANTES DE ABRIR LA TRANSACCION
            THROW 50027, 'La calificación debe estar entre 1 y 5.', 1;
 
        BEGIN TRANSACTION;
 
        IF NOT EXISTS (SELECT 1 FROM VidaU.Resennia WITH (HOLDLOCK) WHERE idResennia = @idResennia) -- VALIDA LA LLAVE FORANEA
            THROW 50026, 'La reseña indicada no existe.', 1;
 
        INSERT INTO VidaU.Evaluacion (idResennia, Calificacion, Comentario)
        VALUES (@idResennia, @Calificacion, @Comentario);
 
        DECLARE @idNuevo INT = SCOPE_IDENTITY(); -- ID GENERADO POR IDENTITY
 
        COMMIT TRANSACTION;
        SELECT @idNuevo AS idEvaluacion;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION; -- DESHACE TODO SI ALGO FALLO
        THROW;
    END CATCH
END
GO
 
-- Actualiza los datos de una evaluación existente.
CREATE OR ALTER PROCEDURE VidaU.sp_Evaluacion_Actualizar
    @idEvaluacion INT,
    @idResennia   INT,
    @Calificacion DECIMAL(2,1),
    @Comentario   VARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        IF @Calificacion IS NULL OR @Calificacion NOT BETWEEN 1 AND 5
            THROW 50027, 'La calificación debe estar entre 1 y 5.', 1;
 
        BEGIN TRANSACTION;
 
        IF NOT EXISTS (SELECT 1 FROM VidaU.Evaluacion WITH (UPDLOCK, HOLDLOCK) WHERE idEvaluacion = @idEvaluacion) -- BLOQUEA EL REGISTRO A MODIFICAR
            THROW 50002, 'La evaluación indicada no existe.', 1;
 
        IF NOT EXISTS (SELECT 1 FROM VidaU.Resennia WITH (HOLDLOCK) WHERE idResennia = @idResennia)
            THROW 50026, 'La reseña indicada no existe.', 1;
 
        UPDATE VidaU.Evaluacion
        SET idResennia = @idResennia,
            Calificacion = @Calificacion,
            Comentario = @Comentario
        WHERE idEvaluacion = @idEvaluacion;
 
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO
 
-- Elimina una evaluación. Si otra tabla la referencia, se informa el error.
CREATE OR ALTER PROCEDURE VidaU.sp_Evaluacion_Eliminar
    @idEvaluacion INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
 
        IF NOT EXISTS (SELECT 1 FROM VidaU.Evaluacion WITH (UPDLOCK, HOLDLOCK) WHERE idEvaluacion = @idEvaluacion)
            THROW 50002, 'La evaluación indicada no existe.', 1;
 
        DELETE FROM VidaU.Evaluacion WHERE idEvaluacion = @idEvaluacion;
 
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        DECLARE @Err INT = ERROR_NUMBER(); -- SE GUARDA ANTES DEL ROLLBACK
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        IF @Err = 547 -- ERROR DE LLAVE FORANEA
            THROW 50003, 'No se puede eliminar la evaluación porque tiene registros relacionados.', 1;
        THROW;
    END CATCH
END
GO
 
-- Consulta una evaluación por id, o todas si @idEvaluacion es NULL.
-- @idResennia ES UN FILTRO OPCIONAL: SI SE ENVIA, SOLO DEVUELVE LAS EVALUACIONES DE ESA RESENNIA.
-- SOLO LECTURA: NO NECESITA TRANSACCION EXPLICITA
CREATE OR ALTER PROCEDURE VidaU.sp_Evaluacion_Consultar
    @idEvaluacion INT = NULL,
    @idResennia   INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT idEvaluacion, idResennia, Calificacion, Comentario
    FROM VidaU.Evaluacion
    WHERE (@idEvaluacion IS NULL OR idEvaluacion = @idEvaluacion)
      AND (@idResennia IS NULL OR idResennia = @idResennia)
    ORDER BY idEvaluacion;
END
GO
 
-- Calcula la calificación general de una reseña: promedio de las calificaciones de sus evaluaciones.
-- SI LA RESENNIA NO TIENE EVALUACIONES, EL PROMEDIO ES NULL Y EL TOTAL ES 0.
-- SOLO LECTURA: NO NECESITA TRANSACCION EXPLICITA
CREATE OR ALTER PROCEDURE VidaU.sp_Evaluacion_PromedioResennia
    @idResennia INT
AS
BEGIN
    SET NOCOUNT ON;
 
    IF NOT EXISTS (SELECT 1 FROM VidaU.Resennia WHERE idResennia = @idResennia)
        THROW 50026, 'La reseña indicada no existe.', 1;
 
    SELECT r.idResennia,
           CAST(AVG(e.Calificacion) AS DECIMAL(3,2)) AS CalificacionGeneral,
           COUNT(e.idEvaluacion) AS TotalEvaluaciones
    FROM VidaU.Resennia r
    LEFT JOIN VidaU.Evaluacion e ON e.idResennia = r.idResennia
    WHERE r.idResennia = @idResennia
    GROUP BY r.idResennia;
END
GO

-- >>>>>> Archivo: 20_Autenticacion/fn_Auth_IntentosFallidos.sql
/* ============================================================
   Función: VidaU.fn_Auth_IntentosFallidos
   Sección: Funcion auxiliar: intentos fallidos
   Función: Cuenta los intentos fallidos recientes de un usuario (login y cambio de contraseña).
            LA CUENTA SE REINICIA CON UN LOGIN EXITOSO, UN CAMBIO DE CONTRASENA O UN RESTABLECIMIENTO,
            Y SOLO CONSIDERA LOS ULTIMOS @MinutosVentana MINUTOS.
   ============================================================ */
CREATE OR ALTER FUNCTION VidaU.fn_Auth_IntentosFallidos
(
    @idUsuario      INT,
    @MinutosVentana INT
)
RETURNS INT
AS
BEGIN
    DECLARE @Desde   DATETIME = DATEADD(MINUTE, -@MinutosVentana, GETDATE());
    DECLARE @Reinicio DATETIME = (SELECT MAX(FechaHora)
                                  FROM VidaU.Bitacora
                                  WHERE idUsuario = @idUsuario
                                    AND Accion IN ('LoginExitoso','CambioContrasena','ContrasenaRestablecida'));

    IF @Reinicio IS NOT NULL AND @Reinicio > @Desde
        SET @Desde = @Reinicio; -- SOLO CUENTA LOS FALLOS POSTERIORES AL ULTIMO REINICIO

    RETURN (SELECT COUNT(*)
            FROM VidaU.Bitacora
            WHERE idUsuario = @idUsuario
              AND Accion IN ('LoginFallido','CambioContrasenaFallido')
              AND FechaHora > @Desde);
END
GO

-- >>>>>> Archivo: 20_Autenticacion/sp_Auth_Login.sql
/* ============================================================
   Procedimiento almacenado: VidaU.sp_Auth_Login
   Sección: Login
   Función: Inicia sesión con correo y contraseña.
            - SI LAS CREDENCIALES SON CORRECTAS: REGISTRA 'LoginExitoso' Y DEVUELVE LOS DATOS DEL USUARIO.
            - SI SON INCORRECTAS: REGISTRA 'LoginFallido' Y LANZA 50030 (MISMO MENSAJE SI EL CORREO NO EXISTE,
            PARA NO REVELAR QUE CUENTAS EXISTEN).
            - SI HAY 5 O MAS FALLOS EN LOS ULTIMOS 15 MINUTOS: REGISTRA 'LoginBloqueado' Y LANZA 50031.
   ============================================================ */
CREATE OR ALTER PROCEDURE VidaU.sp_Auth_Login
    @Correo     VARCHAR(150),
    @Contrasena NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @MaxIntentos    INT = 5;
    DECLARE @MinutosBloqueo INT = 15;
    DECLARE @idUsuario      INT;
    DECLARE @Hash           VARBINARY(256);
    DECLARE @Resultado      VARCHAR(20); -- OK, FALLO, BLOQUEADO

    BEGIN TRY
        BEGIN TRANSACTION;

        -- UPDLOCK + HOLDLOCK SERIALIZA LOS INTENTOS DE UN MISMO USUARIO PARA QUE EL CONTEO SEA EXACTO
        SELECT @idUsuario = idUsuario, @Hash = Contrasena
        FROM VidaU.Usuario WITH (UPDLOCK, HOLDLOCK)
        WHERE Correo = @Correo;

        IF @idUsuario IS NULL
        BEGIN
            SET @Resultado = 'FALLO'; -- CORREO INEXISTENTE: NO HAY USUARIO PARA REGISTRAR EN Bitacora
        END
        ELSE IF VidaU.fn_Auth_IntentosFallidos(@idUsuario, @MinutosBloqueo) >= @MaxIntentos
        BEGIN
            SET @Resultado = 'BLOQUEADO';
            INSERT INTO VidaU.Bitacora (idUsuario, Accion, TablaAfectada, Descripcion)
            VALUES (@idUsuario, 'LoginBloqueado', 'Usuario', 'Intento de inicio de sesión con la cuenta bloqueada temporalmente.');
        END
        ELSE IF @Contrasena IS NOT NULL AND @Hash = HASHBYTES('SHA2_256', @Contrasena)
        BEGIN
            SET @Resultado = 'OK';
            INSERT INTO VidaU.Bitacora (idUsuario, Accion, TablaAfectada, Descripcion)
            VALUES (@idUsuario, 'LoginExitoso', 'Usuario', 'Inicio de sesión exitoso.');
        END
        ELSE
        BEGIN
            SET @Resultado = 'FALLO';
            INSERT INTO VidaU.Bitacora (idUsuario, Accion, TablaAfectada, Descripcion)
            VALUES (@idUsuario, 'LoginFallido', 'Usuario', 'Intento de inicio de sesión con contraseña incorrecta.');
        END

        COMMIT TRANSACTION; -- SE CONFIRMA ANTES DE LANZAR EL ERROR PARA CONSERVAR EL REGISTRO DE Bitacora

        IF @Resultado = 'BLOQUEADO'
            THROW 50031, 'Cuenta bloqueada temporalmente por demasiados intentos fallidos. Intente más tarde.', 1;

        IF @Resultado = 'FALLO'
            THROW 50030, 'Correo o contraseña incorrectos.', 1;

        SELECT u.idUsuario, u.idRol, r.Nombre AS Rol, u.Nombre, u.Apellidos, u.Correo
        FROM VidaU.Usuario u
        INNER JOIN VidaU.Rol r ON r.idRol = u.idRol
        WHERE u.idUsuario = @idUsuario; -- NO SE DEVUELVE LA CONTRASENA
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

-- >>>>>> Archivo: 20_Autenticacion/sp_Auth_RegistrarUsuario.sql
/* ============================================================
   Procedimiento almacenado: VidaU.sp_Auth_RegistrarUsuario
   Sección: Registro de usuario
   Función: Registra un usuario nuevo. Respeta FK_Usuario_Rol y UQ_Usuario_Correo.
            SI SE ENVIAN @Carnet, @idCarrera Y @AnnoIngreso SE CREA TAMBIEN EL PERFIL DE ESTUDIANTE
            (Estudiante) Y SU RELACION CON LA CARRERA (Carrera_Estudiante) EN LA MISMA TRANSACCION:
            O SE GUARDA TODO O NO SE GUARDA NADA. Estudiante.Carrera SE TOMA DE Carrera.Nombre.
   ============================================================ */
CREATE OR ALTER PROCEDURE VidaU.sp_Auth_RegistrarUsuario
    @idRol       INT,
    @Nombre      VARCHAR(100),
    @Apellidos   VARCHAR(100),
    @Correo      VARCHAR(150),
    @Contrasena  NVARCHAR(100),
    @Carnet      VARCHAR(20) = NULL,
    @idCarrera   INT = NULL,
    @AnnoIngreso INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON; -- ROLLBACK AUTOMATICO ANTE CUALQUIER ERROR DE EJECUCION

    DECLARE @idUsuarioNuevo    INT;
    DECLARE @idEstudianteNuevo INT = NULL;
    DECLARE @NombreCarrera     VARCHAR(150);

    BEGIN TRY
        -- VALIDACIONES QUE NO NECESITAN LA BASE DE DATOS (ANTES DE ABRIR LA TRANSACCION)
        IF @Correo IS NULL OR @Correo NOT LIKE '%_@_%._%' OR @Correo LIKE '% %'
            THROW 50036, 'El correo no tiene un formato válido.', 1;

        IF @Contrasena IS NULL OR LEN(@Contrasena) < 8
            THROW 50028, 'La contraseña debe tener al menos 8 caracteres.', 1;

        IF (@Carnet IS NOT NULL OR @idCarrera IS NOT NULL OR @AnnoIngreso IS NOT NULL)
           AND (@Carnet IS NULL OR @idCarrera IS NULL OR @AnnoIngreso IS NULL)
            THROW 50029, 'Para crear el perfil de estudiante se requieren carnet, carrera y año de ingreso.', 1;

        IF @AnnoIngreso IS NOT NULL AND @AnnoIngreso < 2000
            THROW 50014, 'El año de ingreso debe ser mayor o igual a 2000.', 1;

        BEGIN TRANSACTION;

        IF NOT EXISTS (SELECT 1 FROM VidaU.Rol WITH (HOLDLOCK) WHERE idRol = @idRol) -- VALIDA LA LLAVE FORANEA
            THROW 50011, 'El rol indicado no existe.', 1;

        -- UPDLOCK + HOLDLOCK BLOQUEA EL RANGO PARA QUE OTRA SESION NO REGISTRE EL MISMO CORREO A LA VEZ
        IF EXISTS (SELECT 1 FROM VidaU.Usuario WITH (UPDLOCK, HOLDLOCK) WHERE Correo = @Correo)
            THROW 50001, 'Ya existe un usuario con ese correo.', 1;

        INSERT INTO VidaU.Usuario (idRol, Nombre, Apellidos, Correo, Contrasena)
        VALUES (@idRol, @Nombre, @Apellidos, @Correo, HASHBYTES('SHA2_256', @Contrasena));

        SET @idUsuarioNuevo = SCOPE_IDENTITY();

        IF @Carnet IS NOT NULL -- PERFIL DE ESTUDIANTE
        BEGIN
            SELECT @NombreCarrera = Nombre
            FROM VidaU.Carrera WITH (HOLDLOCK)
            WHERE idCarrera = @idCarrera;

            IF @NombreCarrera IS NULL
                THROW 50020, 'La carrera indicada no existe.', 1;

            IF EXISTS (SELECT 1 FROM VidaU.Estudiante WITH (UPDLOCK, HOLDLOCK) WHERE Carnet = @Carnet)
                THROW 50001, 'Ya existe un estudiante con ese carnet.', 1;

            INSERT INTO VidaU.Estudiante (idUsuario, Carnet, Carrera, AnnoIngreso)
            VALUES (@idUsuarioNuevo, @Carnet, @NombreCarrera, @AnnoIngreso);

            SET @idEstudianteNuevo = SCOPE_IDENTITY();

            INSERT INTO VidaU.Carrera_Estudiante (idCarrera, idEstudiante)
            VALUES (@idCarrera, @idEstudianteNuevo);
        END

        INSERT INTO VidaU.Bitacora (idUsuario, Accion, TablaAfectada, Descripcion)
        VALUES (@idUsuarioNuevo, 'Registro', 'Usuario',
                CASE WHEN @Carnet IS NULL THEN 'Usuario registrado.'
                     ELSE 'Usuario registrado con perfil de estudiante.' END);

        COMMIT TRANSACTION;
        SELECT @idUsuarioNuevo AS idUsuario, @idEstudianteNuevo AS idEstudiante;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION; -- DESHACE TODO SI ALGO FALLO
        THROW;
    END CATCH
END
GO

-- >>>>>> Archivo: 20_Autenticacion/sp_Auth_CambiarContrasena.sql
/* ============================================================
   Procedimiento almacenado: VidaU.sp_Auth_CambiarContrasena
   Sección: Cambio de contraseña
   Función: Cambia la contraseña de un usuario que conoce la actual.
            UNA CONTRASENA ACTUAL INCORRECTA SE REGISTRA COMO 'CambioContrasenaFallido' Y CUENTA PARA EL
            BLOQUEO, PARA QUE ESTE PROCEDIMIENTO NO SIRVA PARA ADIVINAR CONTRASENAS SIN LIMITE.
   ============================================================ */
CREATE OR ALTER PROCEDURE VidaU.sp_Auth_CambiarContrasena
    @idUsuario        INT,
    @ContrasenaActual NVARCHAR(100),
    @ContrasenaNueva  NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @MaxIntentos    INT = 5;
    DECLARE @MinutosBloqueo INT = 15;
    DECLARE @Hash           VARBINARY(256);
    DECLARE @Resultado      VARCHAR(20); -- OK, FALLO, BLOQUEADO

    BEGIN TRY
        IF @ContrasenaNueva IS NULL OR LEN(@ContrasenaNueva) < 8
            THROW 50028, 'La contraseña debe tener al menos 8 caracteres.', 1;

        BEGIN TRANSACTION;

        SELECT @Hash = Contrasena
        FROM VidaU.Usuario WITH (UPDLOCK, HOLDLOCK)
        WHERE idUsuario = @idUsuario;

        IF @Hash IS NULL
            THROW 50013, 'El usuario indicado no existe.', 1;

        IF VidaU.fn_Auth_IntentosFallidos(@idUsuario, @MinutosBloqueo) >= @MaxIntentos
        BEGIN
            SET @Resultado = 'BLOQUEADO';
            INSERT INTO VidaU.Bitacora (idUsuario, Accion, TablaAfectada, Descripcion)
            VALUES (@idUsuario, 'CambioContrasenaBloqueado', 'Usuario', 'Intento de cambio de contraseña con la cuenta bloqueada temporalmente.');
        END
        ELSE IF @ContrasenaActual IS NULL OR @Hash <> HASHBYTES('SHA2_256', @ContrasenaActual)
        BEGIN
            SET @Resultado = 'FALLO';
            INSERT INTO VidaU.Bitacora (idUsuario, Accion, TablaAfectada, Descripcion)
            VALUES (@idUsuario, 'CambioContrasenaFallido', 'Usuario', 'Intento de cambio de contraseña con la contraseña actual incorrecta.');
        END
        ELSE
        BEGIN
            IF @Hash = HASHBYTES('SHA2_256', @ContrasenaNueva)
                THROW 50035, 'La nueva contraseña debe ser distinta de la actual.', 1;

            UPDATE VidaU.Usuario
            SET Contrasena = HASHBYTES('SHA2_256', @ContrasenaNueva)
            WHERE idUsuario = @idUsuario;

            INSERT INTO VidaU.Bitacora (idUsuario, Accion, TablaAfectada, Descripcion)
            VALUES (@idUsuario, 'CambioContrasena', 'Usuario', 'Contraseña cambiada por el propio usuario.');

            SET @Resultado = 'OK';
        END

        COMMIT TRANSACTION; -- SE CONFIRMA ANTES DE LANZAR EL ERROR PARA CONSERVAR EL REGISTRO DE Bitacora

        IF @Resultado = 'BLOQUEADO'
            THROW 50031, 'Cuenta bloqueada temporalmente por demasiados intentos fallidos. Intente más tarde.', 1;

        IF @Resultado = 'FALLO'
            THROW 50032, 'La contraseña actual es incorrecta.', 1;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

-- >>>>>> Archivo: 20_Autenticacion/sp_Auth_RestablecerContrasena.sql
/* ============================================================
   Procedimiento almacenado: VidaU.sp_Auth_RestablecerContrasena
   Sección: Restablecer contraseña (administrador)
   Función: Restablece la contraseña de otro usuario. Solo un usuario con el rol de administrador puede hacerlo.
            REGISTRA LA ACCION PARA EL USUARIO AFECTADO ('ContrasenaRestablecida', QUE TAMBIEN LIBERA UN BLOQUEO)
            Y PARA EL ADMINISTRADOR ('RestablecerContrasenaAdmin').
   ============================================================ */
CREATE OR ALTER PROCEDURE VidaU.sp_Auth_RestablecerContrasena
    @idUsuarioAdmin    INT,
    @idUsuarioObjetivo INT,
    @ContrasenaNueva   NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @NombreRolAdmin VARCHAR(50) = 'Administrador';

    BEGIN TRY
        IF @ContrasenaNueva IS NULL OR LEN(@ContrasenaNueva) < 8
            THROW 50028, 'La contraseña debe tener al menos 8 caracteres.', 1;

        BEGIN TRANSACTION;

        IF NOT EXISTS (SELECT 1
                       FROM VidaU.Usuario u WITH (HOLDLOCK)
                       INNER JOIN VidaU.Rol r WITH (HOLDLOCK) ON r.idRol = u.idRol
                       WHERE u.idUsuario = @idUsuarioAdmin AND r.Nombre = @NombreRolAdmin) -- VALIDA EL PERMISO
            THROW 50033, 'No tiene permisos de administrador para realizar esta acción.', 1;

        IF NOT EXISTS (SELECT 1 FROM VidaU.Usuario WITH (UPDLOCK, HOLDLOCK) WHERE idUsuario = @idUsuarioObjetivo)
            THROW 50013, 'El usuario indicado no existe.', 1;

        UPDATE VidaU.Usuario
        SET Contrasena = HASHBYTES('SHA2_256', @ContrasenaNueva)
        WHERE idUsuario = @idUsuarioObjetivo;

        INSERT INTO VidaU.Bitacora (idUsuario, Accion, TablaAfectada, Descripcion)
        VALUES (@idUsuarioObjetivo, 'ContrasenaRestablecida', 'Usuario',
                CONCAT('Contraseña restablecida por el administrador #', @idUsuarioAdmin, '.'));

        INSERT INTO VidaU.Bitacora (idUsuario, Accion, TablaAfectada, Descripcion)
        VALUES (@idUsuarioAdmin, 'RestablecerContrasenaAdmin', 'Usuario',
                CONCAT('Restableció la contraseña del usuario #', @idUsuarioObjetivo, '.'));

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

-- >>>>>> Archivo: 20_Autenticacion/sp_Auth_CambiarRol.sql
/* ============================================================
   Procedimiento almacenado: VidaU.sp_Auth_CambiarRol
   Sección: Cambio de rol (administrador)
   Función: Cambia el rol de un usuario. Solo un usuario con el rol de administrador puede hacerlo.
   ============================================================ */
CREATE OR ALTER PROCEDURE VidaU.sp_Auth_CambiarRol
    @idUsuarioAdmin    INT,
    @idUsuarioObjetivo INT,
    @idRolNuevo        INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @NombreRolAdmin VARCHAR(50) = 'Administrador';
    DECLARE @NombreRolNuevo VARCHAR(50);

    BEGIN TRY
        BEGIN TRANSACTION;

        IF NOT EXISTS (SELECT 1
                       FROM VidaU.Usuario u WITH (HOLDLOCK)
                       INNER JOIN VidaU.Rol r WITH (HOLDLOCK) ON r.idRol = u.idRol
                       WHERE u.idUsuario = @idUsuarioAdmin AND r.Nombre = @NombreRolAdmin)
            THROW 50033, 'No tiene permisos de administrador para realizar esta acción.', 1;

        IF NOT EXISTS (SELECT 1 FROM VidaU.Usuario WITH (UPDLOCK, HOLDLOCK) WHERE idUsuario = @idUsuarioObjetivo)
            THROW 50013, 'El usuario indicado no existe.', 1;

        SELECT @NombreRolNuevo = Nombre
        FROM VidaU.Rol WITH (HOLDLOCK)
        WHERE idRol = @idRolNuevo;

        IF @NombreRolNuevo IS NULL
            THROW 50011, 'El rol indicado no existe.', 1;

        UPDATE VidaU.Usuario
        SET idRol = @idRolNuevo
        WHERE idUsuario = @idUsuarioObjetivo;

        INSERT INTO VidaU.Bitacora (idUsuario, Accion, TablaAfectada, Descripcion)
        VALUES (@idUsuarioAdmin, 'CambioRol', 'Usuario',
                CONCAT('Cambió el rol del usuario #', @idUsuarioObjetivo, ' a ', @NombreRolNuevo, '.'));

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

-- >>>>>> Archivo: 20_Autenticacion/sp_Auth_ObtenerPerfil.sql
/* ============================================================
   Procedimiento almacenado: VidaU.sp_Auth_ObtenerPerfil
   Sección: Perfil de usuario
   Función: Devuelve el perfil de un usuario en dos resultados:
            1) DATOS DEL USUARIO, SU ROL Y, SI ES ESTUDIANTE, SU PERFIL ACADEMICO (Estudiante).
            2) UNIVERSIDADES, SEDES Y CARRERAS DEL ESTUDIANTE (Carrera_Estudiante -> Sede_Carrera -> Sede ->
            Universidad), CON SI LA UNIVERSIDAD TIENE UNA SUSCRIPCION VIGENTE (Suscripcion).
            SOLO LECTURA: NO NECESITA TRANSACCION EXPLICITA. NO SE DEVUELVE LA CONTRASENA.
   ============================================================ */
CREATE OR ALTER PROCEDURE VidaU.sp_Auth_ObtenerPerfil
    @idUsuario INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM VidaU.Usuario WHERE idUsuario = @idUsuario)
        THROW 50013, 'El usuario indicado no existe.', 1;

    SELECT u.idUsuario, u.Nombre, u.Apellidos, u.Correo,
           r.idRol, r.Nombre AS Rol,
           e.idEstudiante, e.Carnet, e.Carrera AS CarreraEstudiante, e.AnnoIngreso
    FROM VidaU.Usuario u
    INNER JOIN VidaU.Rol r ON r.idRol = u.idRol
    LEFT JOIN VidaU.Estudiante e ON e.idUsuario = u.idUsuario
    WHERE u.idUsuario = @idUsuario;

    SELECT un.idUniversidad, un.Nombre AS Universidad, un.Estado AS EstadoUniversidad,
           s.idSede, s.Nombre AS Sede,
           c.idCarrera, c.Nombre AS Carrera,
           CASE WHEN EXISTS (SELECT 1
                             FROM VidaU.Suscripcion su
                             WHERE su.idUniversidad = un.idUniversidad
                               AND su.Estado = 'Activa'
                               AND su.FechaInicio <= CAST(GETDATE() AS DATE)
                               AND (su.FechaFin IS NULL OR su.FechaFin >= CAST(GETDATE() AS DATE)))
                THEN 1 ELSE 0 END AS SuscripcionVigente
    FROM VidaU.Estudiante e
    INNER JOIN VidaU.Carrera_Estudiante ce ON ce.idEstudiante = e.idEstudiante
    INNER JOIN VidaU.Carrera c ON c.idCarrera = ce.idCarrera
    INNER JOIN VidaU.Sede_Carrera sc ON sc.idCarrera = ce.idCarrera
    INNER JOIN VidaU.Sede s ON s.idSede = sc.idSede
    INNER JOIN VidaU.Universidad un ON un.idUniversidad = s.idUniversidad
    WHERE e.idUsuario = @idUsuario
    ORDER BY un.Nombre, s.Nombre, c.Nombre;
END
GO

-- >>>>>> Archivo: 20_Autenticacion/sp_Auth_ConsultarHistorial.sql
/* ============================================================
   Procedimiento almacenado: VidaU.sp_Auth_ConsultarHistorial
   Sección: Historial de autenticación
   Función: Devuelve los últimos eventos de autenticación de un usuario (los más recientes primero).
            @Top ES LA CANTIDAD DE EVENTOS A DEVOLVER (POR DEFECTO 20).
            SOLO LECTURA: NO NECESITA TRANSACCION EXPLICITA
   ============================================================ */
CREATE OR ALTER PROCEDURE VidaU.sp_Auth_ConsultarHistorial
    @idUsuario INT,
    @Top       INT = 20
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM VidaU.Usuario WHERE idUsuario = @idUsuario)
        THROW 50013, 'El usuario indicado no existe.', 1;

    IF @Top IS NULL OR @Top < 1
        SET @Top = 20;

    SELECT TOP (@Top) idBitacora, Accion, TablaAfectada, FechaHora, Descripcion
    FROM VidaU.Bitacora
    WHERE idUsuario = @idUsuario
      AND Accion IN ('Registro','LoginExitoso','LoginFallido','LoginBloqueado','Logout',
                     'CambioContrasena','CambioContrasenaFallido','CambioContrasenaBloqueado',
                     'ContrasenaRestablecida','RestablecerContrasenaAdmin','CambioRol')
    ORDER BY FechaHora DESC, idBitacora DESC;
END
GO

-- >>>>>> Archivo: 20_Autenticacion/sp_Auth_Logout.sql
/* ============================================================
   Procedimiento almacenado: VidaU.sp_Auth_Logout
   Sección: Logout
   Función: Registra el cierre de sesión de un usuario en Bitacora.
            LA SESION COMO TAL LA CONTROLA LA APLICACION; AQUI SOLO QUEDA LA TRAZABILIDAD.
   ============================================================ */
CREATE OR ALTER PROCEDURE VidaU.sp_Auth_Logout
    @idUsuario INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        IF NOT EXISTS (SELECT 1 FROM VidaU.Usuario WITH (HOLDLOCK) WHERE idUsuario = @idUsuario)
            THROW 50013, 'El usuario indicado no existe.', 1;

        INSERT INTO VidaU.Bitacora (idUsuario, Accion, TablaAfectada, Descripcion)
        VALUES (@idUsuario, 'Logout', 'Usuario', 'Cierre de sesión.');

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO


-- ============================================================================
-- VERIFICACION: debe mostrar 85 SQL_STORED_PROCEDURE y 1 SQL_SCALAR_FUNCTION
-- ============================================================================
SELECT o.type_desc AS tipo, COUNT(*) AS cantidad
FROM sys.objects o
WHERE o.schema_id = SCHEMA_ID('VidaU') AND o.type IN ('P','FN')
GROUP BY o.type_desc;
GO