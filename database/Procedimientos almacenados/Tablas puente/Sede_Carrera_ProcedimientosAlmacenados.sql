/* "Sede_Carrera" */
 
-- Agrega la relación entre una sede y una carrera. Respeta FK_SedeCarr_Sede,
-- FK_SedeCarr_Carrera y PK_Sede_Carrera (la misma pareja no se repite).
CREATE OR ALTER PROCEDURE VidaU.sp_Sede_Carrera_Agregar
    @idSede    INT,
    @idCarrera INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
 
        IF NOT EXISTS (SELECT 1 FROM VidaU.Sede WITH (HOLDLOCK) WHERE idSede = @idSede)
            THROW 50019, 'La sede indicada no existe.', 1;
 
        IF NOT EXISTS (SELECT 1 FROM VidaU.Carrera WITH (HOLDLOCK) WHERE idCarrera = @idCarrera)
            THROW 50020, 'La carrera indicada no existe.', 1;
 
        IF EXISTS (SELECT 1 FROM VidaU.Sede_Carrera WITH (UPDLOCK, HOLDLOCK)
                   WHERE idSede = @idSede AND idCarrera = @idCarrera)
            THROW 50001, 'La carrera ya está asociada a esa sede.', 1;
 
        INSERT INTO VidaU.Sede_Carrera (idSede, idCarrera)
        VALUES (@idSede, @idCarrera);
 
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO
 
-- Cambia una pareja sede-carrera existente por otra pareja.
CREATE OR ALTER PROCEDURE VidaU.sp_Sede_Carrera_Actualizar
    @idSedeAnterior    INT,
    @idCarreraAnterior INT,
    @idSedeNueva       INT,
    @idCarreraNueva    INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
 
        IF NOT EXISTS (SELECT 1 FROM VidaU.Sede_Carrera WITH (UPDLOCK, HOLDLOCK)
                       WHERE idSede = @idSedeAnterior AND idCarrera = @idCarreraAnterior)
            THROW 50002, 'La relación indicada no existe.', 1;
 
        IF NOT EXISTS (SELECT 1 FROM VidaU.Sede WITH (HOLDLOCK) WHERE idSede = @idSedeNueva)
            THROW 50019, 'La sede indicada no existe.', 1;
 
        IF NOT EXISTS (SELECT 1 FROM VidaU.Carrera WITH (HOLDLOCK) WHERE idCarrera = @idCarreraNueva)
            THROW 50020, 'La carrera indicada no existe.', 1;
 
        IF (@idSedeNueva <> @idSedeAnterior OR @idCarreraNueva <> @idCarreraAnterior)
           AND EXISTS (SELECT 1 FROM VidaU.Sede_Carrera WITH (UPDLOCK, HOLDLOCK)
                       WHERE idSede = @idSedeNueva AND idCarrera = @idCarreraNueva)
            THROW 50001, 'La carrera ya está asociada a esa sede.', 1;
 
        UPDATE VidaU.Sede_Carrera
        SET idSede = @idSedeNueva,
            idCarrera = @idCarreraNueva
        WHERE idSede = @idSedeAnterior AND idCarrera = @idCarreraAnterior;
 
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO
 
-- Elimina la relación entre una sede y una carrera.
CREATE OR ALTER PROCEDURE VidaU.sp_Sede_Carrera_Eliminar
    @idSede    INT,
    @idCarrera INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
 
        IF NOT EXISTS (SELECT 1 FROM VidaU.Sede_Carrera WITH (UPDLOCK, HOLDLOCK)
                       WHERE idSede = @idSede AND idCarrera = @idCarrera)
            THROW 50002, 'La relación indicada no existe.', 1;
 
        DELETE FROM VidaU.Sede_Carrera
        WHERE idSede = @idSede AND idCarrera = @idCarrera;
 
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        DECLARE @Err INT = ERROR_NUMBER();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        IF @Err = 547
            THROW 50003, 'No se puede eliminar la relación porque tiene registros relacionados.', 1;
        THROW;
    END CATCH
END
GO
 
-- Consulta las relaciones sede-carrera. Cada parámetro en NULL no filtra.
-- SOLO LECTURA: NO NECESITA TRANSACCION EXPLICITA
CREATE OR ALTER PROCEDURE VidaU.sp_Sede_Carrera_Consultar
    @idSede    INT = NULL,
    @idCarrera INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT idSede, idCarrera
    FROM VidaU.Sede_Carrera
    WHERE (@idSede IS NULL OR idSede = @idSede)
      AND (@idCarrera IS NULL OR idCarrera = @idCarrera)
    ORDER BY idSede, idCarrera;
END
GO