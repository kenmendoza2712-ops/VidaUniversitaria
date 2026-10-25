/* "Universidad" */
 
-- Agrega una universidad. Respeta UQ_Universidad_Correo y CK_Universidad_Estado.
-- SI @Estado ES NULL SE USA EL VALOR POR DEFECTO 'Activa'
CREATE OR ALTER PROCEDURE VidaU.sp_Universidad_Agregar
    @Nombre   VARCHAR(150),
    @Correo   VARCHAR(150),
    @Estado   VARCHAR(20) = NULL,
    @Telefono VARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON; -- ROLLBACK AUTOMATICO ANTE CUALQUIER ERROR DE EJECUCION
    BEGIN TRY
        SET @Estado = ISNULL(@Estado, 'Activa');
 
        IF @Estado NOT IN ('Activa','Inactiva') -- VALIDA LA REGLA DEL CHECK ANTES DE ABRIR LA TRANSACCION
            THROW 50005, 'El estado debe ser Activa o Inactiva.', 1;
 
        BEGIN TRANSACTION;
 
        -- UPDLOCK + HOLDLOCK BLOQUEA EL RANGO PARA QUE OTRA SESION NO INSERTE EL MISMO CORREO A LA VEZ
        IF EXISTS (SELECT 1 FROM VidaU.Universidad WITH (UPDLOCK, HOLDLOCK) WHERE Correo = @Correo) -- VALIDA CORREO UNICO
            THROW 50001, 'Ya existe una universidad con ese correo.', 1;
 
        INSERT INTO VidaU.Universidad (Nombre, Correo, Estado, Telefono)
        VALUES (@Nombre, @Correo, @Estado, @Telefono);
 
        DECLARE @idNuevo INT = SCOPE_IDENTITY(); -- ID GENERADO POR IDENTITY
 
        COMMIT TRANSACTION;
        SELECT @idNuevo AS idUniversidad;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION; -- DESHACE TODO SI ALGO FALLO
        THROW;
    END CATCH
END
GO
 
-- Actualiza los datos de una universidad existente.
CREATE OR ALTER PROCEDURE VidaU.sp_Universidad_Actualizar
    @idUniversidad INT,
    @Nombre        VARCHAR(150),
    @Correo        VARCHAR(150),
    @Estado        VARCHAR(20),
    @Telefono      VARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        IF @Estado NOT IN ('Activa','Inactiva')
            THROW 50005, 'El estado debe ser Activa o Inactiva.', 1;
 
        BEGIN TRANSACTION;
 
        IF NOT EXISTS (SELECT 1 FROM VidaU.Universidad WITH (UPDLOCK, HOLDLOCK) WHERE idUniversidad = @idUniversidad) -- BLOQUEA EL REGISTRO A MODIFICAR
            THROW 50002, 'La universidad indicada no existe.', 1;
 
        IF EXISTS (SELECT 1 FROM VidaU.Universidad WITH (UPDLOCK, HOLDLOCK) WHERE Correo = @Correo AND idUniversidad <> @idUniversidad) -- EXCLUYE EL PROPIO REGISTRO
            THROW 50001, 'Ya existe otra universidad con ese correo.', 1;
 
        UPDATE VidaU.Universidad
        SET Nombre = @Nombre,
            Correo = @Correo,
            Estado = @Estado,
            Telefono = @Telefono
        WHERE idUniversidad = @idUniversidad;
 
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO
 
-- Elimina una universidad. Si tiene sedes, suscripciones o profesores relacionados, se informa el error.
CREATE OR ALTER PROCEDURE VidaU.sp_Universidad_Eliminar
    @idUniversidad INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
 
        IF NOT EXISTS (SELECT 1 FROM VidaU.Universidad WITH (UPDLOCK, HOLDLOCK) WHERE idUniversidad = @idUniversidad)
            THROW 50002, 'La universidad indicada no existe.', 1;
 
        DELETE FROM VidaU.Universidad WHERE idUniversidad = @idUniversidad;
 
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        DECLARE @Err INT = ERROR_NUMBER(); -- SE GUARDA ANTES DEL ROLLBACK
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        IF @Err = 547 -- ERROR DE LLAVE FORANEA
            THROW 50003, 'No se puede eliminar la universidad porque tiene registros relacionados.', 1;
        THROW;
    END CATCH
END
GO
 
-- Consulta una universidad por id, o todas si @idUniversidad es NULL.
-- SOLO LECTURA: NO NECESITA TRANSACCION EXPLICITA
CREATE OR ALTER PROCEDURE VidaU.sp_Universidad_Consultar
    @idUniversidad INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT idUniversidad, Nombre, Correo, Estado, Telefono
    FROM VidaU.Universidad
    WHERE (@idUniversidad IS NULL OR idUniversidad = @idUniversidad)
    ORDER BY idUniversidad;
END
GO
 