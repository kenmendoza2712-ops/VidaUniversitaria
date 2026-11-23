USE VidaUniversitariaDB
GO

/* ============================================================
   Función: VidaU.fn_Auth_IntentosFallidos
   Sección: Funcion auxiliar: intentos fallidos
   Función: Cuenta los intentos fallidos recientes de un usuario (login y cambio de contraseña).
            LA CUENTA SE REINICIA CON UN LOGIN EXITOSO, UN CAMBIO DE CONTRASENA O UN RESTABLECIMIENTO,
            Y SOLO CONSIDERA LOS ULTIMOS @MinutosVentana MINUTOS.
   ============================================================ */
CREATE OR ALTER FUNCTION VidaU.fn_Auth_IntentosFallidos
(
    @idUsuario      INT,
    @MinutosVentana INT
)
RETURNS INT
AS
BEGIN
    DECLARE @Desde   DATETIME = DATEADD(MINUTE, -@MinutosVentana, GETDATE());
    DECLARE @Reinicio DATETIME = (SELECT MAX(FechaHora)
                                  FROM VidaU.Bitacora
                                  WHERE idUsuario = @idUsuario
                                    AND Accion IN ('LoginExitoso','CambioContrasena','ContrasenaRestablecida'));

    IF @Reinicio IS NOT NULL AND @Reinicio > @Desde
        SET @Desde = @Reinicio; -- SOLO CUENTA LOS FALLOS POSTERIORES AL ULTIMO REINICIO

    RETURN (SELECT COUNT(*)
            FROM VidaU.Bitacora
            WHERE idUsuario = @idUsuario
              AND Accion IN ('LoginFallido','CambioContrasenaFallido')
              AND FechaHora > @Desde);
END
GO
GO

/* ============================================================
   Procedimiento almacenado: VidaU.sp_Auth_CambiarContrasena
   Sección: Cambio de contraseña
   Función: Cambia la contraseña de un usuario que conoce la actual.
            UNA CONTRASENA ACTUAL INCORRECTA SE REGISTRA COMO 'CambioContrasenaFallido' Y CUENTA PARA EL
            BLOQUEO, PARA QUE ESTE PROCEDIMIENTO NO SIRVA PARA ADIVINAR CONTRASENAS SIN LIMITE.
   ============================================================ */
CREATE OR ALTER PROCEDURE VidaU.sp_Auth_CambiarContrasena
    @idUsuario        INT,
    @ContrasenaActual NVARCHAR(100),
    @ContrasenaNueva  NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @MaxIntentos    INT = 5;
    DECLARE @MinutosBloqueo INT = 15;
    DECLARE @Hash           VARBINARY(256);
    DECLARE @Resultado      VARCHAR(20); -- OK, FALLO, BLOQUEADO

    BEGIN TRY
        IF @ContrasenaNueva IS NULL OR LEN(@ContrasenaNueva) < 8
            THROW 50028, 'La contraseña debe tener al menos 8 caracteres.', 1;

        BEGIN TRANSACTION;

        SELECT @Hash = Contrasena
        FROM VidaU.Usuario WITH (UPDLOCK, HOLDLOCK)
        WHERE idUsuario = @idUsuario;

        IF @Hash IS NULL
            THROW 50013, 'El usuario indicado no existe.', 1;

        IF VidaU.fn_Auth_IntentosFallidos(@idUsuario, @MinutosBloqueo) >= @MaxIntentos
        BEGIN
            SET @Resultado = 'BLOQUEADO';
            INSERT INTO VidaU.Bitacora (idUsuario, Accion, TablaAfectada, Descripcion)
            VALUES (@idUsuario, 'CambioContrasenaBloqueado', 'Usuario', 'Intento de cambio de contraseña con la cuenta bloqueada temporalmente.');
        END
        ELSE IF @ContrasenaActual IS NULL OR @Hash <> HASHBYTES('SHA2_256', @ContrasenaActual)
        BEGIN
            SET @Resultado = 'FALLO';
            INSERT INTO VidaU.Bitacora (idUsuario, Accion, TablaAfectada, Descripcion)
            VALUES (@idUsuario, 'CambioContrasenaFallido', 'Usuario', 'Intento de cambio de contraseña con la contraseña actual incorrecta.');
        END
        ELSE
        BEGIN
            IF @Hash = HASHBYTES('SHA2_256', @ContrasenaNueva)
                THROW 50035, 'La nueva contraseña debe ser distinta de la actual.', 1;

            UPDATE VidaU.Usuario
            SET Contrasena = HASHBYTES('SHA2_256', @ContrasenaNueva)
            WHERE idUsuario = @idUsuario;

            INSERT INTO VidaU.Bitacora (idUsuario, Accion, TablaAfectada, Descripcion)
            VALUES (@idUsuario, 'CambioContrasena', 'Usuario', 'Contraseña cambiada por el propio usuario.');

            SET @Resultado = 'OK';
        END

        COMMIT TRANSACTION; -- SE CONFIRMA ANTES DE LANZAR EL ERROR PARA CONSERVAR EL REGISTRO DE Bitacora

        IF @Resultado = 'BLOQUEADO'
            THROW 50031, 'Cuenta bloqueada temporalmente por demasiados intentos fallidos. Intente más tarde.', 1;

        IF @Resultado = 'FALLO'
            THROW 50032, 'La contraseña actual es incorrecta.', 1;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO
GO

/* ============================================================
   Procedimiento almacenado: VidaU.sp_Auth_CambiarRol
   Sección: Cambio de rol (administrador)
   Función: Cambia el rol de un usuario. Solo un usuario con el rol de administrador puede hacerlo.
   ============================================================ */
CREATE OR ALTER PROCEDURE VidaU.sp_Auth_CambiarRol
    @idUsuarioAdmin    INT,
    @idUsuarioObjetivo INT,
    @idRolNuevo        INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @NombreRolAdmin VARCHAR(50) = 'Administrador';
    DECLARE @NombreRolNuevo VARCHAR(50);

    BEGIN TRY
        BEGIN TRANSACTION;

        IF NOT EXISTS (SELECT 1
                       FROM VidaU.Usuario u WITH (HOLDLOCK)
                       INNER JOIN VidaU.Rol r WITH (HOLDLOCK) ON r.idRol = u.idRol
                       WHERE u.idUsuario = @idUsuarioAdmin AND r.Nombre = @NombreRolAdmin)
            THROW 50033, 'No tiene permisos de administrador para realizar esta acción.', 1;

        IF NOT EXISTS (SELECT 1 FROM VidaU.Usuario WITH (UPDLOCK, HOLDLOCK) WHERE idUsuario = @idUsuarioObjetivo)
            THROW 50013, 'El usuario indicado no existe.', 1;

        SELECT @NombreRolNuevo = Nombre
        FROM VidaU.Rol WITH (HOLDLOCK)
        WHERE idRol = @idRolNuevo;

        IF @NombreRolNuevo IS NULL
            THROW 50011, 'El rol indicado no existe.', 1;

        UPDATE VidaU.Usuario
        SET idRol = @idRolNuevo
        WHERE idUsuario = @idUsuarioObjetivo;

        INSERT INTO VidaU.Bitacora (idUsuario, Accion, TablaAfectada, Descripcion)
        VALUES (@idUsuarioAdmin, 'CambioRol', 'Usuario',
                CONCAT('Cambió el rol del usuario #', @idUsuarioObjetivo, ' a ', @NombreRolNuevo, '.'));

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO
GO

/* ============================================================
   Procedimiento almacenado: VidaU.sp_Auth_ConsultarHistorial
   Sección: Historial de autenticación
   Función: Devuelve los últimos eventos de autenticación de un usuario (los más recientes primero).
            @Top ES LA CANTIDAD DE EVENTOS A DEVOLVER (POR DEFECTO 20).
            SOLO LECTURA: NO NECESITA TRANSACCION EXPLICITA
   ============================================================ */
CREATE OR ALTER PROCEDURE VidaU.sp_Auth_ConsultarHistorial
    @idUsuario INT,
    @Top       INT = 20
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM VidaU.Usuario WHERE idUsuario = @idUsuario)
        THROW 50013, 'El usuario indicado no existe.', 1;

    IF @Top IS NULL OR @Top < 1
        SET @Top = 20;

    SELECT TOP (@Top) idBitacora, Accion, TablaAfectada, FechaHora, Descripcion
    FROM VidaU.Bitacora
    WHERE idUsuario = @idUsuario
      AND Accion IN ('Registro','LoginExitoso','LoginFallido','LoginBloqueado','Logout',
                     'CambioContrasena','CambioContrasenaFallido','CambioContrasenaBloqueado',
                     'ContrasenaRestablecida','RestablecerContrasenaAdmin','CambioRol')
    ORDER BY FechaHora DESC, idBitacora DESC;
END
GO
GO

/* ============================================================
   Procedimiento almacenado: VidaU.sp_Auth_Login
   Sección: Login
   Función: Inicia sesión con correo y contraseña.
            - SI LAS CREDENCIALES SON CORRECTAS: REGISTRA 'LoginExitoso' Y DEVUELVE LOS DATOS DEL USUARIO.
            - SI SON INCORRECTAS: REGISTRA 'LoginFallido' Y LANZA 50030 (MISMO MENSAJE SI EL CORREO NO EXISTE,
            PARA NO REVELAR QUE CUENTAS EXISTEN).
            - SI HAY 5 O MAS FALLOS EN LOS ULTIMOS 15 MINUTOS: REGISTRA 'LoginBloqueado' Y LANZA 50031.
   ============================================================ */
CREATE OR ALTER PROCEDURE VidaU.sp_Auth_Login
    @Correo     VARCHAR(150),
    @Contrasena NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @MaxIntentos    INT = 5;
    DECLARE @MinutosBloqueo INT = 15;
    DECLARE @idUsuario      INT;
    DECLARE @Hash           VARBINARY(256);
    DECLARE @Resultado      VARCHAR(20); -- OK, FALLO, BLOQUEADO

    BEGIN TRY
        BEGIN TRANSACTION;

        -- UPDLOCK + HOLDLOCK SERIALIZA LOS INTENTOS DE UN MISMO USUARIO PARA QUE EL CONTEO SEA EXACTO
        SELECT @idUsuario = idUsuario, @Hash = Contrasena
        FROM VidaU.Usuario WITH (UPDLOCK, HOLDLOCK)
        WHERE Correo = @Correo;

        IF @idUsuario IS NULL
        BEGIN
            SET @Resultado = 'FALLO'; -- CORREO INEXISTENTE: NO HAY USUARIO PARA REGISTRAR EN Bitacora
        END
        ELSE IF VidaU.fn_Auth_IntentosFallidos(@idUsuario, @MinutosBloqueo) >= @MaxIntentos
        BEGIN
            SET @Resultado = 'BLOQUEADO';
            INSERT INTO VidaU.Bitacora (idUsuario, Accion, TablaAfectada, Descripcion)
            VALUES (@idUsuario, 'LoginBloqueado', 'Usuario', 'Intento de inicio de sesión con la cuenta bloqueada temporalmente.');
        END
        ELSE IF @Contrasena IS NOT NULL AND @Hash = HASHBYTES('SHA2_256', @Contrasena)
        BEGIN
            SET @Resultado = 'OK';
            INSERT INTO VidaU.Bitacora (idUsuario, Accion, TablaAfectada, Descripcion)
            VALUES (@idUsuario, 'LoginExitoso', 'Usuario', 'Inicio de sesión exitoso.');
        END
        ELSE
        BEGIN
            SET @Resultado = 'FALLO';
            INSERT INTO VidaU.Bitacora (idUsuario, Accion, TablaAfectada, Descripcion)
            VALUES (@idUsuario, 'LoginFallido', 'Usuario', 'Intento de inicio de sesión con contraseña incorrecta.');
        END

        COMMIT TRANSACTION; -- SE CONFIRMA ANTES DE LANZAR EL ERROR PARA CONSERVAR EL REGISTRO DE Bitacora

        IF @Resultado = 'BLOQUEADO'
            THROW 50031, 'Cuenta bloqueada temporalmente por demasiados intentos fallidos. Intente más tarde.', 1;

        IF @Resultado = 'FALLO'
            THROW 50030, 'Correo o contraseña incorrectos.', 1;

        SELECT u.idUsuario, u.idRol, r.Nombre AS Rol, u.Nombre, u.Apellidos, u.Correo
        FROM VidaU.Usuario u
        INNER JOIN VidaU.Rol r ON r.idRol = u.idRol
        WHERE u.idUsuario = @idUsuario; -- NO SE DEVUELVE LA CONTRASENA
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO
GO

/* ============================================================
   Procedimiento almacenado: VidaU.sp_Auth_Logout
   Sección: Logout
   Función: Registra el cierre de sesión de un usuario en Bitacora.
            LA SESION COMO TAL LA CONTROLA LA APLICACION; AQUI SOLO QUEDA LA TRAZABILIDAD.
   ============================================================ */
CREATE OR ALTER PROCEDURE VidaU.sp_Auth_Logout
    @idUsuario INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        IF NOT EXISTS (SELECT 1 FROM VidaU.Usuario WITH (HOLDLOCK) WHERE idUsuario = @idUsuario)
            THROW 50013, 'El usuario indicado no existe.', 1;

        INSERT INTO VidaU.Bitacora (idUsuario, Accion, TablaAfectada, Descripcion)
        VALUES (@idUsuario, 'Logout', 'Usuario', 'Cierre de sesión.');

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO
GO

/* ============================================================
   Procedimiento almacenado: VidaU.sp_Auth_ObtenerPerfil
   Sección: Perfil de usuario
   Función: Devuelve el perfil de un usuario en dos resultados:
            1) DATOS DEL USUARIO, SU ROL Y, SI ES ESTUDIANTE, SU PERFIL ACADEMICO (Estudiante).
            2) UNIVERSIDADES, SEDES Y CARRERAS DEL ESTUDIANTE (Carrera_Estudiante -> Sede_Carrera -> Sede ->
            Universidad), CON SI LA UNIVERSIDAD TIENE UNA SUSCRIPCION VIGENTE (Suscripcion).
            SOLO LECTURA: NO NECESITA TRANSACCION EXPLICITA. NO SE DEVUELVE LA CONTRASENA.
   ============================================================ */
CREATE OR ALTER PROCEDURE VidaU.sp_Auth_ObtenerPerfil
    @idUsuario INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM VidaU.Usuario WHERE idUsuario = @idUsuario)
        THROW 50013, 'El usuario indicado no existe.', 1;

    SELECT u.idUsuario, u.Nombre, u.Apellidos, u.Correo,
           r.idRol, r.Nombre AS Rol,
           e.idEstudiante, e.Carnet, e.Carrera AS CarreraEstudiante, e.AnnoIngreso
    FROM VidaU.Usuario u
    INNER JOIN VidaU.Rol r ON r.idRol = u.idRol
    LEFT JOIN VidaU.Estudiante e ON e.idUsuario = u.idUsuario
    WHERE u.idUsuario = @idUsuario;

    SELECT un.idUniversidad, un.Nombre AS Universidad, un.Estado AS EstadoUniversidad,
           s.idSede, s.Nombre AS Sede,
           c.idCarrera, c.Nombre AS Carrera,
           CASE WHEN EXISTS (SELECT 1
                             FROM VidaU.Suscripcion su
                             WHERE su.idUniversidad = un.idUniversidad
                               AND su.Estado = 'Activa'
                               AND su.FechaInicio <= CAST(GETDATE() AS DATE)
                               AND (su.FechaFin IS NULL OR su.FechaFin >= CAST(GETDATE() AS DATE)))
                THEN 1 ELSE 0 END AS SuscripcionVigente
    FROM VidaU.Estudiante e
    INNER JOIN VidaU.Carrera_Estudiante ce ON ce.idEstudiante = e.idEstudiante
    INNER JOIN VidaU.Carrera c ON c.idCarrera = ce.idCarrera
    INNER JOIN VidaU.Sede_Carrera sc ON sc.idCarrera = ce.idCarrera
    INNER JOIN VidaU.Sede s ON s.idSede = sc.idSede
    INNER JOIN VidaU.Universidad un ON un.idUniversidad = s.idUniversidad
    WHERE e.idUsuario = @idUsuario
    ORDER BY un.Nombre, s.Nombre, c.Nombre;
END
GO
GO

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
GO

/* ============================================================
   Procedimiento almacenado: VidaU.sp_Auth_RestablecerContrasena
   Sección: Restablecer contraseña (administrador)
   Función: Restablece la contraseña de otro usuario. Solo un usuario con el rol de administrador puede hacerlo.
            REGISTRA LA ACCION PARA EL USUARIO AFECTADO ('ContrasenaRestablecida', QUE TAMBIEN LIBERA UN BLOQUEO)
            Y PARA EL ADMINISTRADOR ('RestablecerContrasenaAdmin').
   ============================================================ */
CREATE OR ALTER PROCEDURE VidaU.sp_Auth_RestablecerContrasena
    @idUsuarioAdmin    INT,
    @idUsuarioObjetivo INT,
    @ContrasenaNueva   NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @NombreRolAdmin VARCHAR(50) = 'Administrador';

    BEGIN TRY
        IF @ContrasenaNueva IS NULL OR LEN(@ContrasenaNueva) < 8
            THROW 50028, 'La contraseña debe tener al menos 8 caracteres.', 1;

        BEGIN TRANSACTION;

        IF NOT EXISTS (SELECT 1
                       FROM VidaU.Usuario u WITH (HOLDLOCK)
                       INNER JOIN VidaU.Rol r WITH (HOLDLOCK) ON r.idRol = u.idRol
                       WHERE u.idUsuario = @idUsuarioAdmin AND r.Nombre = @NombreRolAdmin) -- VALIDA EL PERMISO
            THROW 50033, 'No tiene permisos de administrador para realizar esta acción.', 1;

        IF NOT EXISTS (SELECT 1 FROM VidaU.Usuario WITH (UPDLOCK, HOLDLOCK) WHERE idUsuario = @idUsuarioObjetivo)
            THROW 50013, 'El usuario indicado no existe.', 1;

        UPDATE VidaU.Usuario
        SET Contrasena = HASHBYTES('SHA2_256', @ContrasenaNueva)
        WHERE idUsuario = @idUsuarioObjetivo;

        INSERT INTO VidaU.Bitacora (idUsuario, Accion, TablaAfectada, Descripcion)
        VALUES (@idUsuarioObjetivo, 'ContrasenaRestablecida', 'Usuario',
                CONCAT('Contraseña restablecida por el administrador #', @idUsuarioAdmin, '.'));

        INSERT INTO VidaU.Bitacora (idUsuario, Accion, TablaAfectada, Descripcion)
        VALUES (@idUsuarioAdmin, 'RestablecerContrasenaAdmin', 'Usuario',
                CONCAT('Restableció la contraseña del usuario #', @idUsuarioObjetivo, '.'));

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO
GO

