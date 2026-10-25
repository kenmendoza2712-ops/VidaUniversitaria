/* "Plan" */
 
-- Agrega un plan nuevo. Respeta CK_Plan_Monto (Monto >= 0).
-- PLAN ES PALABRA RESERVADA, POR ESO SE ESCRIBE ENTRE CORCHETES [Plan]
CREATE OR ALTER PROCEDURE VidaU.sp_Plan_Agregar
    @Nombre      VARCHAR(100),
    @Descripcion VARCHAR(300) = NULL,
    @Monto       DECIMAL(10,2)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON; -- ROLLBACK AUTOMATICO ANTE CUALQUIER ERROR DE EJECUCION
    BEGIN TRY
        IF @Monto < 0 -- VALIDA LA REGLA DEL CHECK ANTES DE ABRIR LA TRANSACCION
            THROW 50004, 'El monto debe ser mayor o igual a 0.', 1;
 
        BEGIN TRANSACTION;
 
        INSERT INTO VidaU.[Plan] (Nombre, Descripcion, Monto)
        VALUES (@Nombre, @Descripcion, @Monto);
 
        DECLARE @idNuevo INT = SCOPE_IDENTITY(); -- ID GENERADO POR IDENTITY
 
        COMMIT TRANSACTION;
        SELECT @idNuevo AS idPlan;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION; -- DESHACE TODO SI ALGO FALLO
        THROW;
    END CATCH
END
GO
 
-- Actualiza nombre, descripción y monto de un plan existente.
CREATE OR ALTER PROCEDURE VidaU.sp_Plan_Actualizar
    @idPlan      INT,
    @Nombre      VARCHAR(100),
    @Descripcion VARCHAR(300) = NULL,
    @Monto       DECIMAL(10,2)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        IF @Monto < 0
            THROW 50004, 'El monto debe ser mayor o igual a 0.', 1;
 
        BEGIN TRANSACTION;
 
        -- UPDLOCK + HOLDLOCK BLOQUEA EL REGISTRO PARA QUE OTRA SESION NO LO ELIMINE O MODIFIQUE MIENTRAS SE ACTUALIZA
        IF NOT EXISTS (SELECT 1 FROM VidaU.[Plan] WITH (UPDLOCK, HOLDLOCK) WHERE idPlan = @idPlan)
            THROW 50002, 'El plan indicado no existe.', 1;
 
        UPDATE VidaU.[Plan]
        SET Nombre = @Nombre,
            Descripcion = @Descripcion,
            Monto = @Monto
        WHERE idPlan = @idPlan;
 
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO
 
-- Elimina un plan. Si tiene suscripciones relacionadas, se informa el error.
CREATE OR ALTER PROCEDURE VidaU.sp_Plan_Eliminar
    @idPlan INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
 
        IF NOT EXISTS (SELECT 1 FROM VidaU.[Plan] WITH (UPDLOCK, HOLDLOCK) WHERE idPlan = @idPlan)
            THROW 50002, 'El plan indicado no existe.', 1;
 
        DELETE FROM VidaU.[Plan] WHERE idPlan = @idPlan;
 
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        DECLARE @Err INT = ERROR_NUMBER(); -- SE GUARDA ANTES DEL ROLLBACK
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        IF @Err = 547 -- ERROR DE LLAVE FORANEA
            THROW 50003, 'No se puede eliminar el plan porque tiene registros relacionados.', 1;
        THROW;
    END CATCH
END
GO
 
-- Consulta un plan por id, o todos los planes si @idPlan es NULL.
-- SOLO LECTURA: NO NECESITA TRANSACCION EXPLICITA
CREATE OR ALTER PROCEDURE VidaU.sp_Plan_Consultar
    @idPlan INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT idPlan, Nombre, Descripcion, Monto
    FROM VidaU.[Plan]
    WHERE (@idPlan IS NULL OR idPlan = @idPlan)
    ORDER BY idPlan;
END
GO