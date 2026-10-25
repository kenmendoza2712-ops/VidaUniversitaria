/* ============================================================
   Procedimiento almacenado: VidaU.sp_Auth_RegistrarUsuario
   Sección: Registro de usuario
   Función: Registra un usuario nuevo. Respeta FK_Usuario_Rol y UQ_Usuario_Correo.
            SI SE ENVIAN @Carnet, @idCarrera Y @AnnoIngreso SE CREA TAMBIEN EL PERFIL DE ESTUDIANTE
            (Estudiante) Y SU RELACION CON LA CARRERA (Carrera_Estudiante) EN LA MISMA TRANSACCION:
            O SE GUARDA TODO O NO SE GUARDA NADA. Estudiante.Carrera SE TOMA DE Carrera.Nombre.
   ============================================================ */
CREATE OR ALTER PROCEDURE VidaU.sp_Auth_RegistrarUsuario
    @idRol       INT,
    @Nombre      VARCHAR(100),
    @Apellidos   VARCHAR(100),
    @Correo      VARCHAR(150),
    @Contrasena  NVARCHAR(100),
    @Carnet      VARCHAR(20) = NULL,
    @idCarrera   INT = NULL,
    @AnnoIngreso INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON; -- ROLLBACK AUTOMATICO ANTE CUALQUIER ERROR DE EJECUCION

    DECLARE @idUsuarioNuevo    INT;
    DECLARE @idEstudianteNuevo INT = NULL;
    DECLARE @NombreCarrera     VARCHAR(150);

    BEGIN TRY
        -- VALIDACIONES QUE NO NECESITAN LA BASE DE DATOS (ANTES DE ABRIR LA TRANSACCION)
        IF @Correo IS NULL OR @Correo NOT LIKE '%_@_%._%' OR @Correo LIKE '% %'
            THROW 50036, 'El correo no tiene un formato válido.', 1;

        IF @Contrasena IS NULL OR LEN(@Contrasena) < 8
            THROW 50028, 'La contraseña debe tener al menos 8 caracteres.', 1;

        IF (@Carnet IS NOT NULL OR @idCarrera IS NOT NULL OR @AnnoIngreso IS NOT NULL)
           AND (@Carnet IS NULL OR @idCarrera IS NULL OR @AnnoIngreso IS NULL)
            THROW 50029, 'Para crear el perfil de estudiante se requieren carnet, carrera y año de ingreso.', 1;

        IF @AnnoIngreso IS NOT NULL AND @AnnoIngreso < 2000
            THROW 50014, 'El año de ingreso debe ser mayor o igual a 2000.', 1;

        BEGIN TRANSACTION;

        IF NOT EXISTS (SELECT 1 FROM VidaU.Rol WITH (HOLDLOCK) WHERE idRol = @idRol) -- VALIDA LA LLAVE FORANEA
            THROW 50011, 'El rol indicado no existe.', 1;

        -- UPDLOCK + HOLDLOCK BLOQUEA EL RANGO PARA QUE OTRA SESION NO REGISTRE EL MISMO CORREO A LA VEZ
        IF EXISTS (SELECT 1 FROM VidaU.Usuario WITH (UPDLOCK, HOLDLOCK) WHERE Correo = @Correo)
            THROW 50001, 'Ya existe un usuario con ese correo.', 1;

        INSERT INTO VidaU.Usuario (idRol, Nombre, Apellidos, Correo, Contrasena)
        VALUES (@idRol, @Nombre, @Apellidos, @Correo, HASHBYTES('SHA2_256', @Contrasena));

        SET @idUsuarioNuevo = SCOPE_IDENTITY();

        IF @Carnet IS NOT NULL -- PERFIL DE ESTUDIANTE
        BEGIN
            SELECT @NombreCarrera = Nombre
            FROM VidaU.Carrera WITH (HOLDLOCK)
            WHERE idCarrera = @idCarrera;

            IF @NombreCarrera IS NULL
                THROW 50020, 'La carrera indicada no existe.', 1;

            IF EXISTS (SELECT 1 FROM VidaU.Estudiante WITH (UPDLOCK, HOLDLOCK) WHERE Carnet = @Carnet)
                THROW 50001, 'Ya existe un estudiante con ese carnet.', 1;

            INSERT INTO VidaU.Estudiante (idUsuario, Carnet, Carrera, AnnoIngreso)
            VALUES (@idUsuarioNuevo, @Carnet, @NombreCarrera, @AnnoIngreso);

            SET @idEstudianteNuevo = SCOPE_IDENTITY();

            INSERT INTO VidaU.Carrera_Estudiante (idCarrera, idEstudiante)
            VALUES (@idCarrera, @idEstudianteNuevo);
        END

        INSERT INTO VidaU.Bitacora (idUsuario, Accion, TablaAfectada, Descripcion)
        VALUES (@idUsuarioNuevo, 'Registro', 'Usuario',
                CASE WHEN @Carnet IS NULL THEN 'Usuario registrado.'
                     ELSE 'Usuario registrado con perfil de estudiante.' END);

        COMMIT TRANSACTION;
        SELECT @idUsuarioNuevo AS idUsuario, @idEstudianteNuevo AS idEstudiante;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION; -- DESHACE TODO SI ALGO FALLO
        THROW;
    END CATCH
END
GO
