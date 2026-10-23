/* "Sede" */
 
-- Agrega una sede nueva. Respeta FK_Sede_Universidad y CK_Sede_Estado.
-- SI @Estado ES NULL SE USA EL VALOR POR DEFECTO 'Activa'
CREATE OR ALTER PROCEDURE VidaU.sp_Sede_Agregar
    @idUniversidad INT,
    @Nombre        VARCHAR(150),
    @Estado        VARCHAR(20) = NULL,
    @Direccion     VARCHAR(250) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON; -- ROLLBACK AUTOMATICO ANTE CUALQUIER ERROR DE EJECUCION
    BEGIN TRY
        SET @Estado = ISNULL(@Estado, 'Activa');
 
        IF @Estado NOT IN ('Activa','Inactiva') -- VALIDA LA REGLA DEL CHECK ANTES DE ABRIR LA TRANSACCION
            THROW 50005, 'El estado debe ser Activa o Inactiva.', 1;
 
        BEGIN TRANSACTION;
 
        IF NOT EXISTS (SELECT 1 FROM VidaU.Universidad WITH (HOLDLOCK) WHERE idUniversidad = @idUniversidad) -- VALIDA LA LLAVE FORANEA
            THROW 50007, 'La universidad indicada no existe.', 1;
 
        INSERT INTO VidaU.Sede (idUniversidad, Nombre, Estado, Direccion)
        VALUES (@idUniversidad, @Nombre, @Estado, @Direccion);
 
        DECLARE @idNuevo INT = SCOPE_IDENTITY(); -- ID GENERADO POR IDENTITY
 
        COMMIT TRANSACTION;
        SELECT @idNuevo AS idSede;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION; -- DESHACE TODO SI ALGO FALLO
        THROW;
    END CATCH
END
GO
 
-- Actualiza los datos de una sede existente.
CREATE OR ALTER PROCEDURE VidaU.sp_Sede_Actualizar
    @idSede        INT,
    @idUniversidad INT,
    @Nombre        VARCHAR(150),
    @Estado        VARCHAR(20),
    @Direccion     VARCHAR(250) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        IF @Estado NOT IN ('Activa','Inactiva')
            THROW 50005, 'El estado debe ser Activa o Inactiva.', 1;
 
        BEGIN TRANSACTION;
 
        IF NOT EXISTS (SELECT 1 FROM VidaU.Sede WITH (UPDLOCK, HOLDLOCK) WHERE idSede = @idSede) -- BLOQUEA EL REGISTRO A MODIFICAR
            THROW 50002, 'La sede indicada no existe.', 1;
 
        IF NOT EXISTS (SELECT 1 FROM VidaU.Universidad WITH (HOLDLOCK) WHERE idUniversidad = @idUniversidad)
            THROW 50007, 'La universidad indicada no existe.', 1;
 
        UPDATE VidaU.Sede
        SET idUniversidad = @idUniversidad,
            Nombre = @Nombre,
            Estado = @Estado,
            Direccion = @Direccion
        WHERE idSede = @idSede;
 
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO
 
-- Elimina una sede. Si está en Sede_Carrera u otras tablas relacionadas, se informa el error.
CREATE OR ALTER PROCEDURE VidaU.sp_Sede_Eliminar
    @idSede INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
 
        IF NOT EXISTS (SELECT 1 FROM VidaU.Sede WITH (UPDLOCK, HOLDLOCK) WHERE idSede = @idSede)
            THROW 50002, 'La sede indicada no existe.', 1;
 
        DELETE FROM VidaU.Sede WHERE idSede = @idSede;
 
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        DECLARE @Err INT = ERROR_NUMBER(); -- SE GUARDA ANTES DEL ROLLBACK
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        IF @Err = 547 -- ERROR DE LLAVE FORANEA
            THROW 50003, 'No se puede eliminar la sede porque tiene registros relacionados.', 1;
        THROW;
    END CATCH
END
GO
 
-- Consulta una sede por id, o todas si @idSede es NULL.
-- SOLO LECTURA: NO NECESITA TRANSACCION EXPLICITA
CREATE OR ALTER PROCEDURE VidaU.sp_Sede_Consultar
    @idSede INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT idSede, idUniversidad, Nombre, Estado, Direccion
    FROM VidaU.Sede
    WHERE (@idSede IS NULL OR idSede = @idSede)
    ORDER BY idSede;
END
GO
 