/* "Resennia" */
 
-- Agrega una reseña nueva. Respeta FK_Resennia_Leccion, FK_Resennia_Estudiante,
-- UQ_Resennia_Estudiante_Leccion (una reseña por estudiante por lección) y CK_Resennia_Estado.
-- NombreCurso Y NombreProfesor NO LOS ENVIA EL USUARIO: SE COPIAN DESDE LA LECCION EN ESTE MOMENTO.
-- SI @Estado ES NULL SE USA 'EnRevision'; SI @EsAnonima ES NULL SE USA 1 (ANONIMA);
-- SI @FechaResennia ES NULL SE USA LA FECHA Y HORA ACTUAL
CREATE OR ALTER PROCEDURE VidaU.sp_Resennia_Agregar
    @idLeccion      INT,
    @idEstudiante   INT,
    @Estado         VARCHAR(20) = NULL,
    @EsAnonima      BIT = NULL,
    @FechaResennia  DATETIME = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
 
    DECLARE @NombreCurso    VARCHAR(150);
    DECLARE @NombreProfesor VARCHAR(200);
 
    BEGIN TRY
        SET @Estado = ISNULL(@Estado, 'EnRevision');
        SET @EsAnonima = ISNULL(@EsAnonima, 1);
        SET @FechaResennia = ISNULL(@FechaResennia, GETDATE());
 
        IF @Estado NOT IN ('Visible','Oculta','EnRevision') -- VALIDA LA REGLA DEL CHECK ANTES DE ABRIR LA TRANSACCION
            THROW 50025, 'El estado debe ser Visible, Oculta o EnRevision.', 1;
 
        BEGIN TRANSACTION;
 
        IF NOT EXISTS (SELECT 1 FROM VidaU.Estudiante WITH (HOLDLOCK) WHERE idEstudiante = @idEstudiante) -- VALIDA LAS LLAVES FORANEAS
            THROW 50021, 'El estudiante indicado no existe.', 1;
 
        -- OBTIENE LOS NOMBRES DESDE LA LECCION Y BLOQUEA LOS REGISTROS DURANTE LA TRANSACCION
        SELECT @NombreCurso = c.Nombre,
               @NombreProfesor = LEFT(p.Nombre + ' ' + p.Apellido, 200)
        FROM VidaU.Leccion l WITH (HOLDLOCK)
        INNER JOIN VidaU.Curso c WITH (HOLDLOCK) ON c.idCurso = l.idCurso
        INNER JOIN VidaU.Profesor p WITH (HOLDLOCK) ON p.idProfesor = l.idProfesor
        WHERE l.idLeccion = @idLeccion;
 
        IF @NombreCurso IS NULL -- NO SE ENCONTRO LA LECCION
            THROW 50022, 'La lección indicada no existe.', 1;
 
        -- UPDLOCK + HOLDLOCK BLOQUEA EL RANGO PARA QUE OTRA SESION NO INSERTE LA MISMA RESENNIA A LA VEZ
        IF EXISTS (SELECT 1 FROM VidaU.Resennia WITH (UPDLOCK, HOLDLOCK)
                   WHERE idEstudiante = @idEstudiante AND idLeccion = @idLeccion) -- VALIDA UNA RESENNIA POR ESTUDIANTE POR LECCION
            THROW 50023, 'El estudiante ya dejó una reseña para esa lección.', 1;
 
        INSERT INTO VidaU.Resennia (idLeccion, idEstudiante, Estado, EsAnonima, NombreCurso, FechaResennia, NombreProfesor)
        VALUES (@idLeccion, @idEstudiante, @Estado, @EsAnonima, @NombreCurso, @FechaResennia, @NombreProfesor);
 
        DECLARE @idNuevo INT = SCOPE_IDENTITY();
 
        COMMIT TRANSACTION;
        SELECT @idNuevo AS idResennia;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO
 
-- Actualiza los datos de una reseña existente.
-- NombreCurso Y NombreProfesor SON COPIAS DEL MOMENTO DE LA RESENNIA: SOLO SE VUELVEN A COPIAR
-- DESDE LA LECCION SI CAMBIA @idLeccion; SI NO, SE CONSERVAN.
-- SI @FechaResennia ES NULL SE CONSERVA LA FECHA ACTUAL DEL REGISTRO
CREATE OR ALTER PROCEDURE VidaU.sp_Resennia_Actualizar
    @idResennia     INT,
    @idLeccion      INT,
    @idEstudiante   INT,
    @Estado         VARCHAR(20),
    @EsAnonima      BIT,
    @FechaResennia  DATETIME = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
 
    DECLARE @idLeccionActual INT;
    DECLARE @NombreCurso     VARCHAR(150);
    DECLARE @NombreProfesor  VARCHAR(200);
 
    BEGIN TRY
        IF @Estado NOT IN ('Visible','Oculta','EnRevision')
            THROW 50025, 'El estado debe ser Visible, Oculta o EnRevision.', 1;
 
        BEGIN TRANSACTION;
 
        -- BLOQUEA EL REGISTRO A MODIFICAR Y GUARDA SU LECCION ACTUAL
        SELECT @idLeccionActual = idLeccion
        FROM VidaU.Resennia WITH (UPDLOCK, HOLDLOCK)
        WHERE idResennia = @idResennia;
 
        IF @idLeccionActual IS NULL
            THROW 50002, 'La reseña indicada no existe.', 1;
 
        IF NOT EXISTS (SELECT 1 FROM VidaU.Estudiante WITH (HOLDLOCK) WHERE idEstudiante = @idEstudiante)
            THROW 50021, 'El estudiante indicado no existe.', 1;
 
        SELECT @NombreCurso = c.Nombre,
               @NombreProfesor = LEFT(p.Nombre + ' ' + p.Apellido, 200)
        FROM VidaU.Leccion l WITH (HOLDLOCK)
        INNER JOIN VidaU.Curso c WITH (HOLDLOCK) ON c.idCurso = l.idCurso
        INNER JOIN VidaU.Profesor p WITH (HOLDLOCK) ON p.idProfesor = l.idProfesor
        WHERE l.idLeccion = @idLeccion;
 
        IF @NombreCurso IS NULL
            THROW 50022, 'La lección indicada no existe.', 1;
 
        IF EXISTS (SELECT 1 FROM VidaU.Resennia WITH (UPDLOCK, HOLDLOCK)
                   WHERE idEstudiante = @idEstudiante AND idLeccion = @idLeccion AND idResennia <> @idResennia) -- EXCLUYE EL PROPIO REGISTRO
            THROW 50023, 'El estudiante ya dejó una reseña para esa lección.', 1;
 
        UPDATE VidaU.Resennia
        SET idLeccion = @idLeccion,
            idEstudiante = @idEstudiante,
            Estado = @Estado,
            EsAnonima = @EsAnonima,
            NombreCurso = CASE WHEN @idLeccion = @idLeccionActual THEN NombreCurso ELSE @NombreCurso END, -- CONSERVA LA COPIA SI LA LECCION NO CAMBIA
            NombreProfesor = CASE WHEN @idLeccion = @idLeccionActual THEN NombreProfesor ELSE @NombreProfesor END,
            FechaResennia = ISNULL(@FechaResennia, FechaResennia) -- CONSERVA LA ACTUAL SI NO SE ENVIA
        WHERE idResennia = @idResennia;
 
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO
 
-- Elimina una reseña. Si tiene evaluaciones relacionadas (tabla Evaluacion), se informa el error.
CREATE OR ALTER PROCEDURE VidaU.sp_Resennia_Eliminar
    @idResennia INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
 
        IF NOT EXISTS (SELECT 1 FROM VidaU.Resennia WITH (UPDLOCK, HOLDLOCK) WHERE idResennia = @idResennia)
            THROW 50002, 'La reseña indicada no existe.', 1;
 
        DELETE FROM VidaU.Resennia WHERE idResennia = @idResennia;
 
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        DECLARE @Err INT = ERROR_NUMBER();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        IF @Err = 547
            THROW 50003, 'No se puede eliminar la reseña porque tiene registros relacionados.', 1;
        THROW;
    END CATCH
END
GO
 
-- Consulta una reseña por id, o todas si @idResennia es NULL.
-- SOLO LECTURA: NO NECESITA TRANSACCION EXPLICITA
CREATE OR ALTER PROCEDURE VidaU.sp_Resennia_Consultar
    @idResennia INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT idResennia, idLeccion, idEstudiante, Estado, EsAnonima,
           NombreCurso, NombreProfesor, FechaResennia
    FROM VidaU.Resennia
    WHERE (@idResennia IS NULL OR idResennia = @idResennia)
    ORDER BY idResennia;
END
GO