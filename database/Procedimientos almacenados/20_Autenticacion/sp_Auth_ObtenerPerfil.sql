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
