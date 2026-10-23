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