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
 