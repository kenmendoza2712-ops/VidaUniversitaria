USE VidaUniversitariaDB
GO

/* "Evaluacion" */
 
-- 1.Agrega una evaluación nueva a una reseña. Respeta FK_Evaluacion_Resennia y
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
 
-- 2.Actualiza los datos de una evaluación existente.
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
 
-- 3.Elimina una evaluación. Si otra tabla la referencia, se informa el error.
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
 
-- 4. Lista las evaluaciones.
-- @idResennia ES UN FILTRO OPCIONAL: SI SE ENVIA, SOLO DEVUELVE LAS EVALUACIONES DE ESA RESENNIA.
-- SOLO LECTURA: NO NECESITA TRANSACCION EXPLICITA
CREATE OR ALTER PROCEDURE VidaU.sp_Evaluacion_Consultar
    @idResennia INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT idEvaluacion, idResennia, Calificacion, Comentario
    FROM VidaU.Evaluacion
    WHERE (@idResennia IS NULL OR idResennia = @idResennia)
    ORDER BY idEvaluacion;
END
GO

-- 5. Consulta una evaluación por id. Lanza 50002 si no existe.
-- SOLO LECTURA: NO NECESITA TRANSACCION EXPLICITA
CREATE OR ALTER PROCEDURE VidaU.sp_Evaluacion_ConsultarPorId
    @idEvaluacion INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM VidaU.Evaluacion WHERE idEvaluacion = @idEvaluacion)
        THROW 50002, 'La evaluación indicada no existe.', 1;

    SELECT idEvaluacion, idResennia, Calificacion, Comentario
    FROM VidaU.Evaluacion
    WHERE idEvaluacion = @idEvaluacion;
END
GO