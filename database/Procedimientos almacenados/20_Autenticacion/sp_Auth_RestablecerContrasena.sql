/* ============================================================
   Procedimiento almacenado: VidaU.sp_Auth_RestablecerContrasena
   Sección: Restablecer contraseña (administrador)
   Función: Restablece la contraseña de otro usuario. Solo un usuario con el rol de administrador puede hacerlo.
            REGISTRA LA ACCION PARA EL USUARIO AFECTADO ('ContrasenaRestablecida', QUE TAMBIEN LIBERA UN BLOQUEO)
            Y PARA EL ADMINISTRADOR ('RestablecerContrasenaAdmin').
   ============================================================ */
CREATE OR ALTER PROCEDURE VidaU.sp_Auth_RestablecerContrasena
    @idUsuarioAdmin    INT,
    @idUsuarioObjetivo INT,
    @ContrasenaNueva   NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @NombreRolAdmin VARCHAR(50) = 'Administrador';

    BEGIN TRY
        IF @ContrasenaNueva IS NULL OR LEN(@ContrasenaNueva) < 8
            THROW 50028, 'La contraseña debe tener al menos 8 caracteres.', 1;

        BEGIN TRANSACTION;

        IF NOT EXISTS (SELECT 1
                       FROM VidaU.Usuario u WITH (HOLDLOCK)
                       INNER JOIN VidaU.Rol r WITH (HOLDLOCK) ON r.idRol = u.idRol
                       WHERE u.idUsuario = @idUsuarioAdmin AND r.Nombre = @NombreRolAdmin) -- VALIDA EL PERMISO
            THROW 50033, 'No tiene permisos de administrador para realizar esta acción.', 1;

        IF NOT EXISTS (SELECT 1 FROM VidaU.Usuario WITH (UPDLOCK, HOLDLOCK) WHERE idUsuario = @idUsuarioObjetivo)
            THROW 50013, 'El usuario indicado no existe.', 1;

        UPDATE VidaU.Usuario
        SET Contrasena = HASHBYTES('SHA2_256', @ContrasenaNueva)
        WHERE idUsuario = @idUsuarioObjetivo;

        INSERT INTO VidaU.Bitacora (idUsuario, Accion, TablaAfectada, Descripcion)
        VALUES (@idUsuarioObjetivo, 'ContrasenaRestablecida', 'Usuario',
                CONCAT('Contraseña restablecida por el administrador #', @idUsuarioAdmin, '.'));

        INSERT INTO VidaU.Bitacora (idUsuario, Accion, TablaAfectada, Descripcion)
        VALUES (@idUsuarioAdmin, 'RestablecerContrasenaAdmin', 'Usuario',
                CONCAT('Restableció la contraseña del usuario #', @idUsuarioObjetivo, '.'));

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO
