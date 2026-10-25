/* ============================================================
   Procedimiento almacenado: VidaU.sp_Auth_ConsultarHistorial
   Sección: Historial de autenticación
   Función: Devuelve los últimos eventos de autenticación de un usuario (los más recientes primero).
            @Top ES LA CANTIDAD DE EVENTOS A DEVOLVER (POR DEFECTO 20).
            SOLO LECTURA: NO NECESITA TRANSACCION EXPLICITA
   ============================================================ */
CREATE OR ALTER PROCEDURE VidaU.sp_Auth_ConsultarHistorial
    @idUsuario INT,
    @Top       INT = 20
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM VidaU.Usuario WHERE idUsuario = @idUsuario)
        THROW 50013, 'El usuario indicado no existe.', 1;

    IF @Top IS NULL OR @Top < 1
        SET @Top = 20;

    SELECT TOP (@Top) idBitacora, Accion, TablaAfectada, FechaHora, Descripcion
    FROM VidaU.Bitacora
    WHERE idUsuario = @idUsuario
      AND Accion IN ('Registro','LoginExitoso','LoginFallido','LoginBloqueado','Logout',
                     'CambioContrasena','CambioContrasenaFallido','CambioContrasenaBloqueado',
                     'ContrasenaRestablecida','RestablecerContrasenaAdmin','CambioRol')
    ORDER BY FechaHora DESC, idBitacora DESC;
END
GO
