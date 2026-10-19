/* "Carrera" */
 
-- Agrega una carrera nueva.
CREATE OR ALTER PROCEDURE VidaU.sp_Carrera_Agregar
    @Nombre      VARCHAR(150),
    @Descripcion VARCHAR(300) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        INSERT INTO VidaU.Carrera (Nombre, Descripcion)
        VALUES (@Nombre, @Descripcion);
 
        SELECT SCOPE_IDENTITY() AS idCarrera;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO
 
-- Actualiza nombre y descripción de una carrera existente.
CREATE OR ALTER PROCEDURE VidaU.sp_Carrera_Actualizar
    @idCarrera   INT,
    @Nombre      VARCHAR(150),
    @Descripcion VARCHAR(300) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM VidaU.Carrera WHERE idCarrera = @idCarrera)
            THROW 50002, 'La carrera indicada no existe.', 1;
 
        UPDATE VidaU.Carrera
        SET Nombre = @Nombre,
            Descripcion = @Descripcion
        WHERE idCarrera = @idCarrera;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO
 
-- Elimina una carrera. Si está en tablas puente (Sede_Carrera, Carrera_Curso, Carrera_Estudiante), se informa el error.
CREATE OR ALTER PROCEDURE VidaU.sp_Carrera_Eliminar
    @idCarrera INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM VidaU.Carrera WHERE idCarrera = @idCarrera)
            THROW 50002, 'La carrera indicada no existe.', 1;
 
        DELETE FROM VidaU.Carrera WHERE idCarrera = @idCarrera;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 547
            THROW 50003, 'No se puede eliminar la carrera porque tiene registros relacionados.', 1;
        THROW;
    END CATCH
END
GO
 
-- Consulta una carrera por id, o todas si @idCarrera es NULL.
CREATE OR ALTER PROCEDURE VidaU.sp_Carrera_Consultar
    @idCarrera INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT idCarrera, Nombre, Descripcion
    FROM VidaU.Carrera
    WHERE (@idCarrera IS NULL OR idCarrera = @idCarrera)
    ORDER BY idCarrera;
END
GO