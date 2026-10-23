/* "Curso" */
 
-- Agrega un curso nuevo. Respeta CK_Curso_Creditos (Creditos > 0).
CREATE OR ALTER PROCEDURE VidaU.sp_Curso_Agregar
    @Nombre      VARCHAR(150),
    @Descripcion VARCHAR(300) = NULL,
    @Creditos    INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON; -- ROLLBACK AUTOMATICO ANTE CUALQUIER ERROR DE EJECUCION
    BEGIN TRY
        IF @Creditos <= 0 -- VALIDA LA REGLA DEL CHECK ANTES DE ABRIR LA TRANSACCION
            THROW 50006, 'Los créditos deben ser mayores a 0.', 1;
 
        BEGIN TRANSACTION;
 
        INSERT INTO VidaU.Curso (Nombre, Descripcion, Creditos)
        VALUES (@Nombre, @Descripcion, @Creditos);
 
        DECLARE @idNuevo INT = SCOPE_IDENTITY(); -- ID GENERADO POR IDENTITY
 
        COMMIT TRANSACTION;
        SELECT @idNuevo AS idCurso;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION; -- DESHACE TODO SI ALGO FALLO
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
    SET XACT_ABORT ON;
    BEGIN TRY
        IF @Creditos <= 0
            THROW 50006, 'Los créditos deben ser mayores a 0.', 1;
 
        BEGIN TRANSACTION;
 
        -- UPDLOCK + HOLDLOCK BLOQUEA EL REGISTRO PARA QUE OTRA SESION NO LO ELIMINE O MODIFIQUE MIENTRAS SE ACTUALIZA
        IF NOT EXISTS (SELECT 1 FROM VidaU.Curso WITH (UPDLOCK, HOLDLOCK) WHERE idCurso = @idCurso)
            THROW 50002, 'El curso indicado no existe.', 1;
 
        UPDATE VidaU.Curso
        SET Nombre = @Nombre,
            Descripcion = @Descripcion,
            Creditos = @Creditos
        WHERE idCurso = @idCurso;
 
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
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
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
 
        IF NOT EXISTS (SELECT 1 FROM VidaU.Curso WITH (UPDLOCK, HOLDLOCK) WHERE idCurso = @idCurso)
            THROW 50002, 'El curso indicado no existe.', 1;
 
        DELETE FROM VidaU.Curso WHERE idCurso = @idCurso;
 
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        DECLARE @Err INT = ERROR_NUMBER(); -- SE GUARDA ANTES DEL ROLLBACK
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        IF @Err = 547 -- ERROR DE LLAVE FORANEA
            THROW 50003, 'No se puede eliminar el curso porque tiene registros relacionados.', 1;
        THROW;
    END CATCH
END
GO
 
-- Consulta un curso por id, o todos si @idCurso es NULL.
-- SOLO LECTURA: NO NECESITA TRANSACCION EXPLICITA
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
 