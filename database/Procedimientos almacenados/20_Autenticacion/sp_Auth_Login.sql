/* ============================================================
   Procedimiento almacenado: VidaU.sp_Auth_Login
   Sección: Login
   Función: Inicia sesión con correo y contraseña.
            - SI LAS CREDENCIALES SON CORRECTAS: REGISTRA 'LoginExitoso' Y DEVUELVE LOS DATOS DEL USUARIO.
            - SI SON INCORRECTAS: REGISTRA 'LoginFallido' Y LANZA 50030 (MISMO MENSAJE SI EL CORREO NO EXISTE,
            PARA NO REVELAR QUE CUENTAS EXISTEN).
            - SI HAY 5 O MAS FALLOS EN LOS ULTIMOS 15 MINUTOS: REGISTRA 'LoginBloqueado' Y LANZA 50031.
   ============================================================ */
CREATE OR ALTER PROCEDURE VidaU.sp_Auth_Login
    @Correo     VARCHAR(150),
    @Contrasena NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @MaxIntentos    INT = 5;
    DECLARE @MinutosBloqueo INT = 15;
    DECLARE @idUsuario      INT;
    DECLARE @Hash           VARBINARY(256);
    DECLARE @Resultado      VARCHAR(20); -- OK, FALLO, BLOQUEADO

    BEGIN TRY
        BEGIN TRANSACTION;

        -- UPDLOCK + HOLDLOCK SERIALIZA LOS INTENTOS DE UN MISMO USUARIO PARA QUE EL CONTEO SEA EXACTO
        SELECT @idUsuario = idUsuario, @Hash = Contrasena
        FROM VidaU.Usuario WITH (UPDLOCK, HOLDLOCK)
        WHERE Correo = @Correo;

        IF @idUsuario IS NULL
        BEGIN
            SET @Resultado = 'FALLO'; -- CORREO INEXISTENTE: NO HAY USUARIO PARA REGISTRAR EN Bitacora
        END
        ELSE IF VidaU.fn_Auth_IntentosFallidos(@idUsuario, @MinutosBloqueo) >= @MaxIntentos
        BEGIN
            SET @Resultado = 'BLOQUEADO';
            INSERT INTO VidaU.Bitacora (idUsuario, Accion, TablaAfectada, Descripcion)
            VALUES (@idUsuario, 'LoginBloqueado', 'Usuario', 'Intento de inicio de sesión con la cuenta bloqueada temporalmente.');
        END
        ELSE IF @Contrasena IS NOT NULL AND @Hash = HASHBYTES('SHA2_256', @Contrasena)
        BEGIN
            SET @Resultado = 'OK';
            INSERT INTO VidaU.Bitacora (idUsuario, Accion, TablaAfectada, Descripcion)
            VALUES (@idUsuario, 'LoginExitoso', 'Usuario', 'Inicio de sesión exitoso.');
        END
        ELSE
        BEGIN
            SET @Resultado = 'FALLO';
            INSERT INTO VidaU.Bitacora (idUsuario, Accion, TablaAfectada, Descripcion)
            VALUES (@idUsuario, 'LoginFallido', 'Usuario', 'Intento de inicio de sesión con contraseña incorrecta.');
        END

        COMMIT TRANSACTION; -- SE CONFIRMA ANTES DE LANZAR EL ERROR PARA CONSERVAR EL REGISTRO DE Bitacora

        IF @Resultado = 'BLOQUEADO'
            THROW 50031, 'Cuenta bloqueada temporalmente por demasiados intentos fallidos. Intente más tarde.', 1;

        IF @Resultado = 'FALLO'
            THROW 50030, 'Correo o contraseña incorrectos.', 1;

        SELECT u.idUsuario, u.idRol, r.Nombre AS Rol, u.Nombre, u.Apellidos, u.Correo
        FROM VidaU.Usuario u
        INNER JOIN VidaU.Rol r ON r.idRol = u.idRol
        WHERE u.idUsuario = @idUsuario; -- NO SE DEVUELVE LA CONTRASENA
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO
