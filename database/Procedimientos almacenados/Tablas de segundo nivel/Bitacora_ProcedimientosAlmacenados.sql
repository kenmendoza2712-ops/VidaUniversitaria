/* "Bitacora" */
 
-- Agrega un registro de bitácora. Respeta FK_Bitacora_Usuario.
-- SI @FechaHora ES NULL SE USA LA FECHA Y HORA ACTUAL (VALOR POR DEFECTO DE LA TABLA)
CREATE OR ALTER PROCEDURE VidaU.sp_Bitacora_Agregar
    @idUsuario     INT,
    @Accion        VARCHAR(100),
    @TablaAfectada VARCHAR(100),
    @FechaHora     DATETIME = NULL,
    @Descripcion   VARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON; -- ROLLBACK AUTOMATICO ANTE CUALQUIER ERROR DE EJECUCION
    BEGIN TRY
        SET @FechaHora = ISNULL(@FechaHora, GETDATE());
 
        BEGIN TRANSACTION;
 
        IF NOT EXISTS (SELECT 1 FROM VidaU.Usuario WITH (HOLDLOCK) WHERE idUsuario = @idUsuario) -- VALIDA LA LLAVE FORANEA
            THROW 50013, 'El usuario indicado no existe.', 1;
 
        INSERT INTO VidaU.Bitacora (idUsuario, Accion, TablaAfectada, FechaHora, Descripcion)
        VALUES (@idUsuario, @Accion, @TablaAfectada, @FechaHora, @Descripcion);
 
        DECLARE @idNuevo INT = SCOPE_IDENTITY(); -- ID GENERADO POR IDENTITY
 
        COMMIT TRANSACTION;
        SELECT @idNuevo AS idBitacora;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION; -- DESHACE TODO SI ALGO FALLO
        THROW;
    END CATCH
END
GO
 
-- Actualiza un registro de bitácora existente.
-- SI @FechaHora ES NULL SE CONSERVA LA FECHA Y HORA ACTUAL DEL REGISTRO
CREATE OR ALTER PROCEDURE VidaU.sp_Bitacora_Actualizar
    @idBitacora    INT,
    @idUsuario     INT,
    @Accion        VARCHAR(100),
    @TablaAfectada VARCHAR(100),
    @FechaHora     DATETIME = NULL,
    @Descripcion   VARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
 
        IF NOT EXISTS (SELECT 1 FROM VidaU.Bitacora WITH (UPDLOCK, HOLDLOCK) WHERE idBitacora = @idBitacora) -- BLOQUEA EL REGISTRO A MODIFICAR
            THROW 50002, 'El registro de bitácora indicado no existe.', 1;
 
        IF NOT EXISTS (SELECT 1 FROM VidaU.Usuario WITH (HOLDLOCK) WHERE idUsuario = @idUsuario)
            THROW 50013, 'El usuario indicado no existe.', 1;
 
        UPDATE VidaU.Bitacora
        SET idUsuario = @idUsuario,
            Accion = @Accion,
            TablaAfectada = @TablaAfectada,
            FechaHora = ISNULL(@FechaHora, FechaHora), -- CONSERVA LA ACTUAL SI NO SE ENVIA
            Descripcion = @Descripcion
        WHERE idBitacora = @idBitacora;
 
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO
 
-- Elimina un registro de bitácora. Si otra tabla lo referencia, se informa el error.
CREATE OR ALTER PROCEDURE VidaU.sp_Bitacora_Eliminar
    @idBitacora INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
 
        IF NOT EXISTS (SELECT 1 FROM VidaU.Bitacora WITH (UPDLOCK, HOLDLOCK) WHERE idBitacora = @idBitacora)
            THROW 50002, 'El registro de bitácora indicado no existe.', 1;
 
        DELETE FROM VidaU.Bitacora WHERE idBitacora = @idBitacora;
 
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        DECLARE @Err INT = ERROR_NUMBER(); -- SE GUARDA ANTES DEL ROLLBACK
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        IF @Err = 547 -- ERROR DE LLAVE FORANEA
            THROW 50003, 'No se puede eliminar el registro de bitácora porque tiene registros relacionados.', 1;
        THROW;
    END CATCH
END
GO
 
-- Consulta un registro de bitácora por id, o todos si @idBitacora es NULL.
-- SOLO LECTURA: NO NECESITA TRANSACCION EXPLICITA
CREATE OR ALTER PROCEDURE VidaU.sp_Bitacora_Consultar
    @idBitacora INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT idBitacora, idUsuario, Accion, TablaAfectada, FechaHora, Descripcion
    FROM VidaU.Bitacora
    WHERE (@idBitacora IS NULL OR idBitacora = @idBitacora)
    ORDER BY idBitacora;
END
GO