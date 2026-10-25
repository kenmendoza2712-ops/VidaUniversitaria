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