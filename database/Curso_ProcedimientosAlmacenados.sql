/* "Curso" */
 
-- Agrega un curso nuevo. Respeta CK_Curso_Creditos (Creditos > 0).
CREATE OR ALTER PROCEDURE VidaU.sp_Curso_Agregar
    @Nombre      VARCHAR(150),
    @Descripcion VARCHAR(300) = NULL,
    @Creditos    INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF @Creditos <= 0 -- VALIDA LA REGLA DEL CHECK ANTES DE INSERTAR
            THROW 50006, 'Los créditos deben ser mayores a 0.', 1;
 
        INSERT INTO VidaU.Curso (Nombre, Descripcion, Creditos)
        VALUES (@Nombre, @Descripcion, @Creditos);
 
        SELECT SCOPE_IDENTITY() AS idCurso;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO
 
-- Actualiza nombre, descripción y créditos de un curso existente.
CREATE OR ALTER PROCEDURE VidaU.sp_Curso_Actualizar
    @idCurso     INT,
    @Nombre      VARCHAR(150),
    @Descripcion VARCHAR(300) = NULL,
    @Creditos    INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM VidaU.Curso WHERE idCurso = @idCurso)
            THROW 50002, 'El curso indicado no existe.', 1;
 
        IF @Creditos <= 0
            THROW 50006, 'Los créditos deben ser mayores a 0.', 1;
 
        UPDATE VidaU.Curso
        SET Nombre = @Nombre,
            Descripcion = @Descripcion,
            Creditos = @Creditos
        WHERE idCurso = @idCurso;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO
 
-- Elimina un curso. Si tiene lecciones o está en Carrera_Curso, se informa el error.
CREATE OR ALTER PROCEDURE VidaU.sp_Curso_Eliminar
    @idCurso INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM VidaU.Curso WHERE idCurso = @idCurso)
            THROW 50002, 'El curso indicado no existe.', 1;
 
        DELETE FROM VidaU.Curso WHERE idCurso = @idCurso;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 547
            THROW 50003, 'No se puede eliminar el curso porque tiene registros relacionados.', 1;
        THROW;
    END CATCH
END
GO
 
-- Consulta un curso por id, o todos si @idCurso es NULL.
CREATE OR ALTER PROCEDURE VidaU.sp_Curso_Consultar
    @idCurso INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT idCurso, Nombre, Descripcion, Creditos
    FROM VidaU.Curso
    WHERE (@idCurso IS NULL OR idCurso = @idCurso)
    ORDER BY idCurso;
END
GO