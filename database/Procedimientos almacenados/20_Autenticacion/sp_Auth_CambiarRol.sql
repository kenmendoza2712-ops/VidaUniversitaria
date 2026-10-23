/* ============================================================
   Procedimiento almacenado: VidaU.sp_Auth_CambiarRol
   Sección: Cambio de rol (administrador)
   Función: Cambia el rol de un usuario. Solo un usuario con el rol de administrador puede hacerlo.
   ============================================================ */
CREATE OR ALTER PROCEDURE VidaU.sp_Auth_CambiarRol
    @idUsuarioAdmin    INT,
    @idUsuarioObjetivo INT,
    @idRolNuevo        INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @NombreRolAdmin VARCHAR(50) = 'Administrador';
    DECLARE @NombreRolNuevo VARCHAR(50);

    BEGIN TRY
        BEGIN TRANSACTION;

        IF NOT EXISTS (SELECT 1
                       FROM VidaU.Usuario u WITH (HOLDLOCK)
                       INNER JOIN VidaU.Rol r WITH (HOLDLOCK) ON r.idRol = u.idRol
                       WHERE u.idUsuario = @idUsuarioAdmin AND r.Nombre = @NombreRolAdmin)
            THROW 50033, 'No tiene permisos de administrador para realizar esta acción.', 1;

        IF NOT EXISTS (SELECT 1 FROM VidaU.Usuario WITH (UPDLOCK, HOLDLOCK) WHERE idUsuario = @idUsuarioObjetivo)
            THROW 50013, 'El usuario indicado no existe.', 1;

        SELECT @NombreRolNuevo = Nombre
        FROM VidaU.Rol WITH (HOLDLOCK)
        WHERE idRol = @idRolNuevo;

        IF @NombreRolNuevo IS NULL
            THROW 50011, 'El rol indicado no existe.', 1;

        UPDATE VidaU.Usuario
        SET idRol = @idRolNuevo
        WHERE idUsuario = @idUsuarioObjetivo;

        INSERT INTO VidaU.Bitacora (idUsuario, Accion, TablaAfectada, Descripcion)
        VALUES (@idUsuarioAdmin, 'CambioRol', 'Usuario',
                CONCAT('Cambió el rol del usuario #', @idUsuarioObjetivo, ' a ', @NombreRolNuevo, '.'));

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO
