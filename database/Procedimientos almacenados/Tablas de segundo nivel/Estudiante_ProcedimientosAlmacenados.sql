/* "Estudiante" */
 
-- Agrega un estudiante nuevo. Respeta FK_Estudiante_Usuario, UQ_Estudiante_Usuario (1:1 con Usuario),
-- UQ_Estudiante_Carnet y CK_Estudiante_AnnoIngreso (AnnoIngreso >= 2000).
CREATE OR ALTER PROCEDURE VidaU.sp_Estudiante_Agregar
    @idUsuario   INT,
    @Carnet      VARCHAR(20),
    @Carrera     VARCHAR(150),
    @AnnoIngreso INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        IF @AnnoIngreso < 2000 -- VALIDA LA REGLA DEL CHECK ANTES DE ABRIR LA TRANSACCION
            THROW 50014, 'El año de ingreso debe ser mayor o igual a 2000.', 1;
 
        BEGIN TRANSACTION;
 
        IF NOT EXISTS (SELECT 1 FROM VidaU.Usuario WITH (HOLDLOCK) WHERE idUsuario = @idUsuario) -- VALIDA LA LLAVE FORANEA
            THROW 50013, 'El usuario indicado no existe.', 1;
 
        -- UPDLOCK + HOLDLOCK BLOQUEA EL RANGO PARA QUE OTRA SESION NO INSERTE EL MISMO USUARIO O CARNET A LA VEZ
        IF EXISTS (SELECT 1 FROM VidaU.Estudiante WITH (UPDLOCK, HOLDLOCK) WHERE idUsuario = @idUsuario) -- VALIDA RELACION 1:1
            THROW 50018, 'El usuario indicado ya tiene un perfil de estudiante.', 1;
 
        IF EXISTS (SELECT 1 FROM VidaU.Estudiante WITH (UPDLOCK, HOLDLOCK) WHERE Carnet = @Carnet) -- VALIDA CARNET UNICO
            THROW 50001, 'Ya existe un estudiante con ese carnet.', 1;
 
        INSERT INTO VidaU.Estudiante (idUsuario, Carnet, Carrera, AnnoIngreso)
        VALUES (@idUsuario, @Carnet, @Carrera, @AnnoIngreso);
 
        DECLARE @idNuevo INT = SCOPE_IDENTITY();
 
        COMMIT TRANSACTION;
        SELECT @idNuevo AS idEstudiante;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO
 
-- Actualiza los datos de un estudiante existente.
CREATE OR ALTER PROCEDURE VidaU.sp_Estudiante_Actualizar
    @idEstudiante INT,
    @idUsuario    INT,
    @Carnet       VARCHAR(20),
    @Carrera      VARCHAR(150),
    @AnnoIngreso  INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        IF @AnnoIngreso < 2000
            THROW 50014, 'El año de ingreso debe ser mayor o igual a 2000.', 1;
 
        BEGIN TRANSACTION;
 
        IF NOT EXISTS (SELECT 1 FROM VidaU.Estudiante WITH (UPDLOCK, HOLDLOCK) WHERE idEstudiante = @idEstudiante) -- BLOQUEA EL REGISTRO A MODIFICAR
            THROW 50002, 'El estudiante indicado no existe.', 1;
 
        IF NOT EXISTS (SELECT 1 FROM VidaU.Usuario WITH (HOLDLOCK) WHERE idUsuario = @idUsuario)
            THROW 50013, 'El usuario indicado no existe.', 1;
 
        IF EXISTS (SELECT 1 FROM VidaU.Estudiante WITH (UPDLOCK, HOLDLOCK) WHERE idUsuario = @idUsuario AND idEstudiante <> @idEstudiante) -- EXCLUYE EL PROPIO REGISTRO
            THROW 50018, 'El usuario indicado ya tiene un perfil de estudiante.', 1;
 
        IF EXISTS (SELECT 1 FROM VidaU.Estudiante WITH (UPDLOCK, HOLDLOCK) WHERE Carnet = @Carnet AND idEstudiante <> @idEstudiante)
            THROW 50001, 'Ya existe otro estudiante con ese carnet.', 1;
 
        UPDATE VidaU.Estudiante
        SET idUsuario = @idUsuario,
            Carnet = @Carnet,
            Carrera = @Carrera,
            AnnoIngreso = @AnnoIngreso
        WHERE idEstudiante = @idEstudiante;
 
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO
 
-- Elimina un estudiante. Si está en Carrera_Estudiante, Matricula o Resennia, se informa el error.
CREATE OR ALTER PROCEDURE VidaU.sp_Estudiante_Eliminar
    @idEstudiante INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
 
        IF NOT EXISTS (SELECT 1 FROM VidaU.Estudiante WITH (UPDLOCK, HOLDLOCK) WHERE idEstudiante = @idEstudiante)
            THROW 50002, 'El estudiante indicado no existe.', 1;
 
        DELETE FROM VidaU.Estudiante WHERE idEstudiante = @idEstudiante;
 
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        DECLARE @Err INT = ERROR_NUMBER();
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        IF @Err = 547
            THROW 50003, 'No se puede eliminar el estudiante porque tiene registros relacionados.', 1;
        THROW;
    END CATCH
END
GO
 
-- Consulta un estudiante por id, o todos si @idEstudiante es NULL.
-- SOLO LECTURA: NO NECESITA TRANSACCION EXPLICITA
CREATE OR ALTER PROCEDURE VidaU.sp_Estudiante_Consultar
    @idEstudiante INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT idEstudiante, idUsuario, Carnet, Carrera, AnnoIngreso
    FROM VidaU.Estudiante
    WHERE (@idEstudiante IS NULL OR idEstudiante = @idEstudiante)
    ORDER BY idEstudiante;
END
GO