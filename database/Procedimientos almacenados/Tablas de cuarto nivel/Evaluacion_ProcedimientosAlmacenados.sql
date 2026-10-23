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