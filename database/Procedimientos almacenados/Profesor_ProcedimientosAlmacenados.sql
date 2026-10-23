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