/* ============================================================
   Procedimiento almacenado: VidaU.sp_Auth_Logout
   Sección: Logout
   Función: Registra el cierre de sesión de un usuario en Bitacora.
            LA SESION COMO TAL LA CONTROLA LA APLICACION; AQUI SOLO QUEDA LA TRAZABILIDAD.
   ============================================================ */
CREATE OR ALTER PROCEDURE VidaU.sp_Auth_Logout
    @idUsuario INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        IF NOT EXISTS (SELECT 1 FROM VidaU.Usuario WITH (HOLDLOCK) WHERE idUsuario = @idUsuario)
            THROW 50013, 'El usuario indicado no existe.', 1;

        INSERT INTO VidaU.Bitacora (idUsuario, Accion, TablaAfectada, Descripcion)
        VALUES (@idUsuario, 'Logout', 'Usuario', 'Cierre de sesión.');

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO
