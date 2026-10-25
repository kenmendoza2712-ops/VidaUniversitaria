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