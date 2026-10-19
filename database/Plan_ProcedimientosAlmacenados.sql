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
    BEGIN TRY
        IF @Monto < 0 -- VALIDA LA REGLA DEL CHECK ANTES DE INSERTAR
            THROW 50004, 'El monto debe ser mayor o igual a 0.', 1;
 
        INSERT INTO VidaU.[Plan] (Nombre, Descripcion, Monto)
        VALUES (@Nombre, @Descripcion, @Monto);
 
        SELECT SCOPE_IDENTITY() AS idPlan;
    END TRY
    BEGIN CATCH
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
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM VidaU.[Plan] WHERE idPlan = @idPlan)
            THROW 50002, 'El plan indicado no existe.', 1;
 
        IF @Monto < 0
            THROW 50004, 'El monto debe ser mayor o igual a 0.', 1;
 
        UPDATE VidaU.[Plan]
        SET Nombre = @Nombre,
            Descripcion = @Descripcion,
            Monto = @Monto
        WHERE idPlan = @idPlan;
    END TRY
    BEGIN CATCH
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
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM VidaU.[Plan] WHERE idPlan = @idPlan)
            THROW 50002, 'El plan indicado no existe.', 1;
 
        DELETE FROM VidaU.[Plan] WHERE idPlan = @idPlan;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 547
            THROW 50003, 'No se puede eliminar el plan porque tiene registros relacionados.', 1;
        THROW;
    END CATCH
END
GO
 
-- Consulta un plan por id, o todos los planes si @idPlan es NULL.
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