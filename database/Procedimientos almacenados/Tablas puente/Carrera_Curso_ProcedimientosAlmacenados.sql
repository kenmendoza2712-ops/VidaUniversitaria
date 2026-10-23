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