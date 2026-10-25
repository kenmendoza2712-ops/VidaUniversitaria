/* "Usuario" */
 
-- Agrega un usuario nuevo. Respeta FK_Usuario_Rol y UQ_Usuario_Correo.
-- LA CONTRASENA LLEGA EN TEXTO Y SE GUARDA CON HASHBYTES (NUNCA EN TEXTO PLANO)
CREATE OR ALTER PROCEDURE VidaU.sp_Usuario_Agregar
    @idRol      INT,
    @Nombre     VARCHAR(100),
    @Apellidos  VARCHAR(100),
    @Correo     VARCHAR(150),
    @Contrasena NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        IF @Contrasena IS NULL OR LTRIM(RTRIM(@Contrasena)) = ''
            THROW 50012, 'La contraseña es obligatoria.', 1;
 
        BEGIN TRANSACTION;
 
        IF NOT EXISTS (SELECT 1 FROM VidaU.Rol WITH (HOLDLOCK) WHERE idRol = @idRol) -- VALIDA LA LLAVE FORANEA
            THROW 50011, 'El rol indicado no existe.', 1;
 
        -- UPDLOCK + HOLDLOCK BLOQUEA EL RANGO PARA QUE OTRA SESION NO INSERTE EL MISMO CORREO A LA VEZ
        IF EXISTS (SELECT 1 FROM VidaU.Usuario WITH (UPDLOCK, HOLDLOCK) WHERE Correo = @Correo) -- VALIDA CORREO UNICO
            THROW 50001, 'Ya existe un usuario con ese correo.', 1;
 
        INSERT INTO VidaU.Usuario (idRol, Nombre, Apellidos, Correo, Contrasena)
        VALUES (@idRol, @Nombre, @Apellidos, @Correo, HASHBYTES('SHA2_256', @Contrasena));
 
        DECLARE @idNuevo INT = SCOPE_IDENTITY();
 
        COMMIT TRANSACTION;
        SELECT @idNuevo AS idUsuario;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO
 
-- Actualiza los datos de un usuario existente.
-- SI @Contrasena ES NULL SE CONSERVA LA CONTRASENA ACTUAL; SI SE ENVIA, SE GUARDA SU HASH.
CREATE OR ALTER PROCEDURE VidaU.sp_Usuario_Actualizar
    @idUsuario  INT,
    @idRol      INT,
    @Nombre     VARCHAR(100),
    @Apellidos  VARCHAR(100),
    @Correo     VARCHAR(150),
    @Contrasena NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        IF @Contrasena IS NOT NULL AND LTRIM(RTRIM(@Contrasena)) = ''
            THROW 50012, 'La contraseña no puede estar vacía.', 1;
 
        BEGIN TRANSACTION;
 
        IF NOT EXISTS (SELECT 1 FROM VidaU.Usuario WITH (UPDLOCK, HOLDLOCK) WHERE idUsuario = @idUsuario) -- BLOQUEA EL REGISTRO A MODIFICAR
            THROW 50002, 'El usuario indicado no existe.', 1;
 
        IF NOT EXISTS (SELECT 1 FROM VidaU.Rol WITH (HOLDLOCK) WHERE idRol = @idRol)
            THROW 50011, 'El rol indicado no existe.', 1;
 
        IF EXISTS (SELECT 1 FROM VidaU.Usuario WITH (UPDLOCK, HOLDLOCK) WHERE Correo = @Correo AND idUsuario <> @idUsuario) -- EXCLUYE EL PROPIO REGISTRO
            THROW 50001, 'Ya existe otro usuario con ese correo.', 1;
 
        UPDATE VidaU.Usuario
        SET idRol = @idRol,
            Nombre = @Nombre,
            Apellidos = @Apellidos,
            Correo = @Correo,
            Contrasena = CASE WHEN @Contrasena IS NULL
                              THEN Contrasena -- CONSERVA LA ACTUAL
                              ELSE HASHBYTES('SHA2_256', @Contrasena) END
        WHERE idUsuario = @idUsuario;
 
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO
 
-- Elimina un usuario. Si está referenciado por Estudiante o Bitacora, se informa el error.
CREATE OR ALTER PROCEDURE VidaU.sp_Usuario_Eliminar
    @idUsuario INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
 
        IF NOT EXISTS (SELECT 1 FROM VidaU.Usuario WITH (UPDLOCK, HOLDLOCK) WHERE idUsuario = @idUsuario)
            THROW 50002, 'El usuario indicado no existe.', 1;
 
        DELETE FROM VidaU.Usuario WHERE idUsuario = @idUsuario;
 
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        DECLARE @Err INT = ERROR_NUMBER();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        IF @Err = 547
            THROW 50003, 'No se puede eliminar el usuario porque tiene registros relacionados.', 1;
        THROW;
    END CATCH
END
GO
 
-- Consulta un usuario por id, o todos si @idUsuario es NULL.
-- SOLO LECTURA: NO NECESITA TRANSACCION EXPLICITA
-- NO SE DEVUELVE LA COLUMNA Contrasena (HASH) POR SEGURIDAD
CREATE OR ALTER PROCEDURE VidaU.sp_Usuario_Consultar
    @idUsuario INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT idUsuario, idRol, Nombre, Apellidos, Correo
    FROM VidaU.Usuario
    WHERE (@idUsuario IS NULL OR idUsuario = @idUsuario)
    ORDER BY idUsuario;
END
GO