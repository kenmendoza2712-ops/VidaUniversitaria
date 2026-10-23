/* "Rol" */
 
-- Agrega un rol nuevo. Respeta UQ_Rol_Nombre (no se repite el nombre).
CREATE OR ALTER PROCEDURE VidaU.sp_Rol_Agregar
    @Nombre      VARCHAR(50),
    @Descripcion VARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON; -- ROLLBACK AUTOMATICO ANTE CUALQUIER ERROR DE EJECUCION
    BEGIN TRY
        BEGIN TRANSACTION;
 
        -- UPDLOCK + HOLDLOCK BLOQUEA EL RANGO PARA QUE OTRA SESION NO INSERTE EL MISMO NOMBRE A LA VEZ
        IF EXISTS (SELECT 1 FROM VidaU.Rol WITH (UPDLOCK, HOLDLOCK) WHERE Nombre = @Nombre) -- VALIDA QUE NO EXISTA OTRO ROL CON EL MISMO NOMBRE
            THROW 50001, 'Ya existe un rol con ese nombre.', 1;
 
        INSERT INTO VidaU.Rol (Nombre, Descripcion)
        VALUES (@Nombre, @Descripcion);
 
        DECLARE @idNuevo INT = SCOPE_IDENTITY(); -- ID GENERADO POR IDENTITY
 
        COMMIT TRANSACTION;
        SELECT @idNuevo AS idRol; -- DEVUELVE EL ID GENERADO
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION; -- DESHACE TODO SI ALGO FALLO
        THROW;
    END CATCH
END
GO
 
-- Actualiza el nombre y la descripción de un rol existente.
CREATE OR ALTER PROCEDURE VidaU.sp_Rol_Actualizar
    @idRol       INT,
    @Nombre      VARCHAR(50),
    @Descripcion VARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
 
        IF NOT EXISTS (SELECT 1 FROM VidaU.Rol WITH (UPDLOCK, HOLDLOCK) WHERE idRol = @idRol) -- BLOQUEA EL REGISTRO A MODIFICAR
            THROW 50002, 'El rol indicado no existe.', 1;
 
        IF EXISTS (SELECT 1 FROM VidaU.Rol WITH (UPDLOCK, HOLDLOCK) WHERE Nombre = @Nombre AND idRol <> @idRol) -- EXCLUYE EL PROPIO REGISTRO
            THROW 50001, 'Ya existe otro rol con ese nombre.', 1;
 
        UPDATE VidaU.Rol
        SET Nombre = @Nombre,
            Descripcion = @Descripcion
        WHERE idRol = @idRol;
 
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO
 
-- Elimina un rol. Si está referenciado por otras tablas (ej. Usuario), se informa el error.
CREATE OR ALTER PROCEDURE VidaU.sp_Rol_Eliminar
    @idRol INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
 
        IF NOT EXISTS (SELECT 1 FROM VidaU.Rol WITH (UPDLOCK, HOLDLOCK) WHERE idRol = @idRol)
            THROW 50002, 'El rol indicado no existe.', 1;
 
        DELETE FROM VidaU.Rol WHERE idRol = @idRol;
 
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        DECLARE @Err INT = ERROR_NUMBER(); -- SE GUARDA ANTES DEL ROLLBACK
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        IF @Err = 547 -- ERROR DE LLAVE FORANEA
            THROW 50003, 'No se puede eliminar el rol porque tiene registros relacionados.', 1;
        THROW;
    END CATCH
END
GO
 
-- Consulta un rol por id, o todos los roles si @idRol es NULL.
-- SOLO LECTURA: NO NECESITA TRANSACCION EXPLICITA
CREATE OR ALTER PROCEDURE VidaU.sp_Rol_Consultar
    @idRol INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT idRol, Nombre, Descripcion
    FROM VidaU.Rol
    WHERE (@idRol IS NULL OR idRol = @idRol)
    ORDER BY idRol;
END
GO