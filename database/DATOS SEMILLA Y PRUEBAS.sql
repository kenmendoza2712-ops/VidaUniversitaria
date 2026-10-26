/* ============================================================================
   Vida Universitaria - Datos semilla y prueba del flujo
   Carga datos de ejemplo USANDO LOS PROPIOS PROCEDIMIENTOS ALMACENADOS, asi que
   ademas de llenar las tablas sirve como prueba de que los procedimientos funcionan.

   REQUISITOS: scripts 01 (tablas), 02 (control de acceso) y 03 (procedimientos) ya ejecutados.
   SE EJECUTA UNA SOLA VEZ: si ya hay roles cargados, el script avisa y se detiene.
   Las contrasenas de abajo son de ejemplo, solo para el entorno de clase.
   ============================================================================ */
USE VidaUniversitariaDB
GO

SET NOCOUNT ON;

-- SI YA HAY DATOS, NO SE VUELVE A CARGAR (EVITA ERRORES POR CORREOS Y CARNETS DUPLICADOS)
IF EXISTS (SELECT 1 FROM VidaU.Rol)
BEGIN
    PRINT 'Los datos semilla ya estan cargados. No se hizo ningun cambio.';
    RETURN;
END

-- TABLA AUXILIAR PARA CAPTURAR EL ID QUE DEVUELVE CADA PROCEDIMIENTO "Agregar"
DECLARE @r TABLE (id INT);

DECLARE @hoy DATE = CAST(GETDATE() AS DATE);
DECLARE @idRolAdmin INT, @idRolEstudiante INT, @idRolCoordinador INT;
DECLARE @idPlanBasico INT, @idPlanInstitucional INT;
DECLARE @idUniversidad INT, @idSede INT, @idCarrera INT;
DECLARE @idCursoBD INT, @idCursoProg INT;
DECLARE @idProfMaria INT, @idProfCarlos INT;
DECLARE @idLeccionBD INT, @idLeccionProg INT;
DECLARE @idEstudiante INT, @idResennia INT;
DECLARE @u TABLE (idUsuario INT, idEstudiante INT NULL);
DECLARE @idUsuarioAdmin INT, @idUsuarioEstudiante INT;

PRINT '=== 1. ROLES ===';
INSERT INTO @r EXEC VidaU.sp_Rol_Agregar @Nombre = 'Administrador', @Descripcion = 'Administra la plataforma y modera las resenias'; -- EL NOMBRE EXACTO "Administrador" LO USAN sp_Auth_CambiarRol Y sp_Auth_RestablecerContrasena
SELECT @idRolAdmin = id FROM @r; DELETE FROM @r;
INSERT INTO @r EXEC VidaU.sp_Rol_Agregar @Nombre = 'Estudiante', @Descripcion = 'Consulta y publica resenias';
SELECT @idRolEstudiante = id FROM @r; DELETE FROM @r;
INSERT INTO @r EXEC VidaU.sp_Rol_Agregar @Nombre = 'Coordinador', @Descripcion = 'Consulta la analitica de su carrera';
SELECT @idRolCoordinador = id FROM @r; DELETE FROM @r;

PRINT '=== 2. PLANES ===';
INSERT INTO @r EXEC VidaU.sp_Plan_Agregar @Nombre = 'Plan Basico', @Descripcion = 'Analitica basica por carrera', @Monto = 100.00;
SELECT @idPlanBasico = id FROM @r; DELETE FROM @r;
INSERT INTO @r EXEC VidaU.sp_Plan_Agregar @Nombre = 'Plan Institucional', @Descripcion = 'Analitica completa y reportes', @Monto = 500.00;
SELECT @idPlanInstitucional = id FROM @r; DELETE FROM @r;

PRINT '=== 3. UNIVERSIDAD, SEDE, SUSCRIPCION ===';
INSERT INTO @r EXEC VidaU.sp_Universidad_Agregar @Nombre = 'Universidad Latina de Costa Rica', @Correo = 'contacto@ulatina.example', @Telefono = '2000-0000';
SELECT @idUniversidad = id FROM @r; DELETE FROM @r;

INSERT INTO @r EXEC VidaU.sp_Sede_Agregar @idUniversidad = @idUniversidad, @Nombre = 'Sede San Pedro', @Direccion = 'San Pedro, San Jose';
SELECT @idSede = id FROM @r; DELETE FROM @r;

DECLARE @finSuscripcion DATE = DATEADD(YEAR, 1, @hoy);
INSERT INTO @r EXEC VidaU.sp_Suscripcion_Agregar @idUniversidad = @idUniversidad, @idPlan = @idPlanInstitucional, @FechaInicio = @hoy, @FechaFin = @finSuscripcion;
DELETE FROM @r;

PRINT '=== 4. CARRERA, CURSOS Y PROFESORES ===';
INSERT INTO @r EXEC VidaU.sp_Carrera_Agregar @Nombre = 'Ingenieria en Tecnologias de la Informacion', @Descripcion = 'Carrera de ejemplo para las pruebas';
SELECT @idCarrera = id FROM @r; DELETE FROM @r;

INSERT INTO @r EXEC VidaU.sp_Curso_Agregar @Nombre = 'Bases de Datos II', @Descripcion = 'Stored procedures, transacciones y optimizacion', @Creditos = 4;
SELECT @idCursoBD = id FROM @r; DELETE FROM @r;
INSERT INTO @r EXEC VidaU.sp_Curso_Agregar @Nombre = 'Programacion I', @Descripcion = 'Fundamentos de programacion', @Creditos = 4;
SELECT @idCursoProg = id FROM @r; DELETE FROM @r;

INSERT INTO @r EXEC VidaU.sp_Profesor_Agregar @Nombre = 'Maria', @Apellido = 'Rojas', @Correo = 'maria.rojas@ulatina.example';
SELECT @idProfMaria = id FROM @r; DELETE FROM @r;
INSERT INTO @r EXEC VidaU.sp_Profesor_Agregar @Nombre = 'Carlos', @Apellido = 'Vargas', @Correo = 'carlos.vargas@ulatina.example';
SELECT @idProfCarlos = id FROM @r; DELETE FROM @r;

PRINT '=== 5. TABLAS PUENTE (RELACIONES MUCHOS A MUCHOS) ===';
EXEC VidaU.sp_Universidad_Profesor_Agregar @idUniversidad = @idUniversidad, @idProfesor = @idProfMaria;
EXEC VidaU.sp_Universidad_Profesor_Agregar @idUniversidad = @idUniversidad, @idProfesor = @idProfCarlos;
EXEC VidaU.sp_Sede_Carrera_Agregar @idSede = @idSede, @idCarrera = @idCarrera;
EXEC VidaU.sp_Carrera_Curso_Agregar @idCarrera = @idCarrera, @idCurso = @idCursoBD;
EXEC VidaU.sp_Carrera_Curso_Agregar @idCarrera = @idCarrera, @idCurso = @idCursoProg;

PRINT '=== 6. LECCIONES ===';
INSERT INTO @r EXEC VidaU.sp_Leccion_Agregar @idCurso = @idCursoBD, @idProfesor = @idProfMaria, @Horario = 'Lunes 6:00 pm - 9:00 pm', @Aula = 'A-101', @Cupo = 30;
SELECT @idLeccionBD = id FROM @r; DELETE FROM @r;
INSERT INTO @r EXEC VidaU.sp_Leccion_Agregar @idCurso = @idCursoProg, @idProfesor = @idProfCarlos, @Horario = 'Miercoles 6:00 pm - 9:00 pm', @Aula = 'B-203', @Cupo = 25;
SELECT @idLeccionProg = id FROM @r; DELETE FROM @r;

PRINT '=== 7. USUARIOS (ADMINISTRADOR Y ESTUDIANTE CON SU PERFIL) ===';
INSERT INTO @u EXEC VidaU.sp_Auth_RegistrarUsuario
    @idRol = @idRolAdmin, @Nombre = 'Ana', @Apellidos = 'Administradora',
    @Correo = 'admin@vidau.example', @Contrasena = 'Admin#2026';
SELECT @idUsuarioAdmin = idUsuario FROM @u; DELETE FROM @u;

-- AL ENVIAR @Carnet, @idCarrera Y @AnnoIngreso SE CREAN TAMBIEN Estudiante Y Carrera_Estudiante
INSERT INTO @u EXEC VidaU.sp_Auth_RegistrarUsuario
    @idRol = @idRolEstudiante, @Nombre = 'Kendall', @Apellidos = 'Quesada',
    @Correo = 'kendall.quesada@vidau.example', @Contrasena = 'Estudiante#2026',
    @Carnet = 'C00001', @idCarrera = @idCarrera, @AnnoIngreso = 2024;
SELECT @idUsuarioEstudiante = idUsuario, @idEstudiante = idEstudiante FROM @u; DELETE FROM @u;

PRINT '=== 8. MATRICULA, RESENNIA Y EVALUACIONES ===';
INSERT INTO @r EXEC VidaU.sp_Matricula_Agregar @idEstudiante = @idEstudiante;
DELETE FROM @r;

INSERT INTO @r EXEC VidaU.sp_Resennia_Agregar @idLeccion = @idLeccionBD, @idEstudiante = @idEstudiante, @Estado = 'Visible', @EsAnonima = 1;
SELECT @idResennia = id FROM @r; DELETE FROM @r;

INSERT INTO @r EXEC VidaU.sp_Evaluacion_Agregar @idResennia = @idResennia, @Calificacion = 4.5, @Comentario = 'Explica con claridad';
DELETE FROM @r;
INSERT INTO @r EXEC VidaU.sp_Evaluacion_Agregar @idResennia = @idResennia, @Calificacion = 5.0, @Comentario = 'Muy buena disponibilidad';
DELETE FROM @r;
INSERT INTO @r EXEC VidaU.sp_Evaluacion_Agregar @idResennia = @idResennia, @Calificacion = 4.0, @Comentario = 'Exigente pero justo';
DELETE FROM @r;

PRINT 'Datos semilla cargados correctamente.';
PRINT '';

/* ============================================================================
   PRUEBAS DEL FLUJO (cada una muestra su resultado en la pestana de resultados)
   ============================================================================ */

PRINT '=== PRUEBA 1: LOGIN CON CONTRASENA INCORRECTA (se espera el error 50030) ===';
BEGIN TRY
    EXEC VidaU.sp_Auth_Login @Correo = 'kendall.quesada@vidau.example', @Contrasena = 'incorrecta123';
END TRY
BEGIN CATCH
    SELECT ERROR_NUMBER() AS codigo_error, ERROR_MESSAGE() AS mensaje;
END CATCH

PRINT '=== PRUEBA 2: LOGIN CORRECTO (devuelve idUsuario, rol, nombre y correo; nunca la contrasena) ===';
EXEC VidaU.sp_Auth_Login @Correo = 'kendall.quesada@vidau.example', @Contrasena = 'Estudiante#2026';

PRINT '=== PRUEBA 3: PERFIL DEL ESTUDIANTE (2 resultados: datos del usuario y sus universidades/sedes/carreras) ===';
EXEC VidaU.sp_Auth_ObtenerPerfil @idUsuario = @idUsuarioEstudiante;

PRINT '=== PRUEBA 4: PROMEDIO DE LA RESENNIA (se espera 4.50 con 3 evaluaciones) ===';
EXEC VidaU.sp_Evaluacion_PromedioResennia @idResennia = @idResennia;

PRINT '=== PRUEBA 5: RESENNIA DUPLICADA (se espera el error 50023: una resenia por estudiante por leccion) ===';
BEGIN TRY
    EXEC VidaU.sp_Resennia_Agregar @idLeccion = @idLeccionBD, @idEstudiante = @idEstudiante;
END TRY
BEGIN CATCH
    SELECT ERROR_NUMBER() AS codigo_error, ERROR_MESSAGE() AS mensaje;
END CATCH

PRINT '=== PRUEBA 6: HISTORIAL DE AUTENTICACION DEL ESTUDIANTE (Registro, LoginFallido, LoginExitoso) ===';
EXEC VidaU.sp_Auth_ConsultarHistorial @idUsuario = @idUsuarioEstudiante;

PRINT '=== PRUEBA 7: CONTEO DE REGISTROS POR TABLA ===';
SELECT 'Rol' AS tabla, COUNT(*) AS filas FROM VidaU.Rol
UNION ALL SELECT 'Plan', COUNT(*) FROM VidaU.[Plan]
UNION ALL SELECT 'Universidad', COUNT(*) FROM VidaU.Universidad
UNION ALL SELECT 'Sede', COUNT(*) FROM VidaU.Sede
UNION ALL SELECT 'Suscripcion', COUNT(*) FROM VidaU.Suscripcion
UNION ALL SELECT 'Carrera', COUNT(*) FROM VidaU.Carrera
UNION ALL SELECT 'Curso', COUNT(*) FROM VidaU.Curso
UNION ALL SELECT 'Profesor', COUNT(*) FROM VidaU.Profesor
UNION ALL SELECT 'Leccion', COUNT(*) FROM VidaU.Leccion
UNION ALL SELECT 'Usuario', COUNT(*) FROM VidaU.Usuario
UNION ALL SELECT 'Estudiante', COUNT(*) FROM VidaU.Estudiante
UNION ALL SELECT 'Matricula', COUNT(*) FROM VidaU.Matricula
UNION ALL SELECT 'Resennia', COUNT(*) FROM VidaU.Resennia
UNION ALL SELECT 'Evaluacion', COUNT(*) FROM VidaU.Evaluacion
UNION ALL SELECT 'Universidad_Profesor', COUNT(*) FROM VidaU.Universidad_Profesor
UNION ALL SELECT 'Sede_Carrera', COUNT(*) FROM VidaU.Sede_Carrera
UNION ALL SELECT 'Carrera_Curso', COUNT(*) FROM VidaU.Carrera_Curso
UNION ALL SELECT 'Carrera_Estudiante', COUNT(*) FROM VidaU.Carrera_Estudiante
UNION ALL SELECT 'Bitacora', COUNT(*) FROM VidaU.Bitacora;
GO