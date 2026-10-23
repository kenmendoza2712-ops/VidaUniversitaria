/* ============================================================
   Procedimiento almacenado: VidaU.sp_Auth_CambiarContrasena
   Sección: Cambio de contraseña
   Función: Cambia la contraseña de un usuario que conoce la actual.
            UNA CONTRASENA ACTUAL INCORRECTA SE REGISTRA COMO 'CambioContrasenaFallido' Y CUENTA PARA EL
            BLOQUEO, PARA QUE ESTE PROCEDIMIENTO NO SIRVA PARA ADIVINAR CONTRASENAS SIN LIMITE.
   ============================================================ */
CREATE OR ALTER PROCEDURE VidaU.sp_Auth_CambiarContrasena
    @idUsuario        INT,
    @ContrasenaActual NVARCHAR(100),
    @ContrasenaNueva  NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @MaxIntentos    INT = 5;
    DECLARE @MinutosBloqueo INT = 15;
    DECLARE @Hash           VARBINARY(256);
    DECLARE @Resultado      VARCHAR(20); -- OK, FALLO, BLOQUEADO

    BEGIN TRY
        IF @ContrasenaNueva IS NULL OR LEN(@ContrasenaNueva) < 8
            THROW 50028, 'La contraseña debe tener al menos 8 caracteres.', 1;

        BEGIN TRANSACTION;

        SELECT @Hash = Contrasena
        FROM VidaU.Usuario WITH (UPDLOCK, HOLDLOCK)
        WHERE idUsuario = @idUsuario;

        IF @Hash IS NULL
            THROW 50013, 'El usuario indicado no existe.', 1;

        IF VidaU.fn_Auth_IntentosFallidos(@idUsuario, @MinutosBloqueo) >= @MaxIntentos
        BEGIN
            SET @Resultado = 'BLOQUEADO';
            INSERT INTO VidaU.Bitacora (idUsuario, Accion, TablaAfectada, Descripcion)
            VALUES (@idUsuario, 'CambioContrasenaBloqueado', 'Usuario', 'Intento de cambio de contraseña con la cuenta bloqueada temporalmente.');
        END
        ELSE IF @ContrasenaActual IS NULL OR @Hash <> HASHBYTES('SHA2_256', @ContrasenaActual)
        BEGIN
            SET @Resultado = 'FALLO';
            INSERT INTO VidaU.Bitacora (idUsuario, Accion, TablaAfectada, Descripcion)
            VALUES (@idUsuario, 'CambioContrasenaFallido', 'Usuario', 'Intento de cambio de contraseña con la contraseña actual incorrecta.');
        END
        ELSE
        BEGIN
            IF @Hash = HASHBYTES('SHA2_256', @ContrasenaNueva)
                THROW 50035, 'La nueva contraseña debe ser distinta de la actual.', 1;

            UPDATE VidaU.Usuario
            SET Contrasena = HASHBYTES('SHA2_256', @ContrasenaNueva)
            WHERE idUsuario = @idUsuario;

            INSERT INTO VidaU.Bitacora (idUsuario, Accion, TablaAfectada, Descripcion)
            VALUES (@idUsuario, 'CambioContrasena', 'Usuario', 'Contraseña cambiada por el propio usuario.');

            SET @Resultado = 'OK';
        END

        COMMIT TRANSACTION; -- SE CONFIRMA ANTES DE LANZAR EL ERROR PARA CONSERVAR EL REGISTRO DE Bitacora

        IF @Resultado = 'BLOQUEADO'
            THROW 50031, 'Cuenta bloqueada temporalmente por demasiados intentos fallidos. Intente más tarde.', 1;

        IF @Resultado = 'FALLO'
            THROW 50032, 'La contraseña actual es incorrecta.', 1;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO
