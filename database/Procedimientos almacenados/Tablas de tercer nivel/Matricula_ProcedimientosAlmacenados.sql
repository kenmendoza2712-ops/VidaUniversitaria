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