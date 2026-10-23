/* "Profesor" */
 
-- Agrega un profesor nuevo. Respeta UQ_Profesor_Correo (no se repite el correo).
CREATE OR ALTER PROCEDURE VidaU.sp_Profesor_Agregar
    @Nombre   VARCHAR(100),
    @Apellido VARCHAR(100),
    @Correo   VARCHAR(150)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF EXISTS (SELECT 1 FROM VidaU.Profesor WHERE Correo = @Correo) -- VALIDA CORREO UNICO
            THROW 50001, 'Ya existe un profesor con ese correo.', 1;
 
        INSERT INTO VidaU.Profesor (Nombre, Apellido, Correo)
        VALUES (@Nombre, @Apellido, @Correo);
 
        SELECT SCOPE_IDENTITY() AS idProfesor;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO
 
-- Actualiza nombre, apellido y correo de un profesor existente.
CREATE OR ALTER PROCEDURE VidaU.sp_Profesor_Actualizar
    @idProfesor INT,
    @Nombre     VARCHAR(100),
    @Apellido   VARCHAR(100),
    @Correo     VARCHAR(150)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM VidaU.Profesor WHERE idProfesor = @idProfesor)
            THROW 50002, 'El profesor indicado no existe.', 1;
 
        IF EXISTS (SELECT 1 FROM VidaU.Profesor WHERE Correo = @Correo AND idProfesor <> @idProfesor)
            THROW 50001, 'Ya existe otro profesor con ese correo.', 1;
 
        UPDATE VidaU.Profesor
        SET Nombre = @Nombre,
            Apellido = @Apellido,
            Correo = @Correo
        WHERE idProfesor = @idProfesor;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO
 
-- Elimina un profesor. Si tiene lecciones o está en Universidad_Profesor, se informa el error.
CREATE OR ALTER PROCEDURE VidaU.sp_Profesor_Eliminar
    @idProfesor INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM VidaU.Profesor WHERE idProfesor = @idProfesor)
            THROW 50002, 'El profesor indicado no existe.', 1;
 
        DELETE FROM VidaU.Profesor WHERE idProfesor = @idProfesor;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 547
            THROW 50003, 'No se puede eliminar el profesor porque tiene registros relacionados.', 1;
        THROW;
    END CATCH
END
GO
 
-- Consulta un profesor por id, o todos si @idProfesor es NULL.
CREATE OR ALTER PROCEDURE VidaU.sp_Profesor_Consultar
    @idProfesor INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT idProfesor, Nombre, Apellido, Correo
    FROM VidaU.Profesor
    WHERE (@idProfesor IS NULL OR idProfesor = @idProfesor)
    ORDER BY idProfesor;
END
GO