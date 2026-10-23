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