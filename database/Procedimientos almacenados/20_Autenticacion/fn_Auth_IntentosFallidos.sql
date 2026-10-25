/* ============================================================
   Función: VidaU.fn_Auth_IntentosFallidos
   Sección: Funcion auxiliar: intentos fallidos
   Función: Cuenta los intentos fallidos recientes de un usuario (login y cambio de contraseña).
            LA CUENTA SE REINICIA CON UN LOGIN EXITOSO, UN CAMBIO DE CONTRASENA O UN RESTABLECIMIENTO,
            Y SOLO CONSIDERA LOS ULTIMOS @MinutosVentana MINUTOS.
   ============================================================ */
CREATE OR ALTER FUNCTION VidaU.fn_Auth_IntentosFallidos
(
    @idUsuario      INT,
    @MinutosVentana INT
)
RETURNS INT
AS
BEGIN
    DECLARE @Desde   DATETIME = DATEADD(MINUTE, -@MinutosVentana, GETDATE());
    DECLARE @Reinicio DATETIME = (SELECT MAX(FechaHora)
                                  FROM VidaU.Bitacora
                                  WHERE idUsuario = @idUsuario
                                    AND Accion IN ('LoginExitoso','CambioContrasena','ContrasenaRestablecida'));

    IF @Reinicio IS NOT NULL AND @Reinicio > @Desde
        SET @Desde = @Reinicio; -- SOLO CUENTA LOS FALLOS POSTERIORES AL ULTIMO REINICIO

    RETURN (SELECT COUNT(*)
            FROM VidaU.Bitacora
            WHERE idUsuario = @idUsuario
              AND Accion IN ('LoginFallido','CambioContrasenaFallido')
              AND FechaHora > @Desde);
END
GO
