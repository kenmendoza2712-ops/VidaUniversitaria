/* ============================================================================
   VIDA UNIVERSITARIA
   DATOS SEMILLA Y PRUEBAS DE PROCEDIMIENTOS ALMACENADOS
   
   ============================================================================ */

USE VidaUniversitariaDB;
GO

SET NOCOUNT ON;
GO

/* ============================================================================
   0. VALIDACIÓN DE REQUISITOS
   Comprueba que la base de datos, el esquema y los procedimientos principales
   existan antes de intentar insertar información.
   ============================================================================ */
IF SCHEMA_ID('VidaU') IS NULL
    THROW 51000, 'No existe el esquema VidaU. Ejecute primero ESQUEMA Y TABLAS.sql.', 1;

IF OBJECT_ID('VidaU.sp_Rol_Agregar', 'P') IS NULL
    THROW 51001, 'No se encuentran los procedimientos almacenados. Ejecute los archivos 01 al 20.', 1;

IF OBJECT_ID('VidaU.sp_Auth_RegistrarUsuario', 'P') IS NULL
    THROW 51002, 'No se encuentra sp_Auth_RegistrarUsuario. Ejecute 20_Autenticacion.sql.', 1;

PRINT 'Validación inicial completada.';

/* ============================================================================
   1. VARIABLES DE TRABAJO
   Guarda los identificadores generados por los procedimientos Agregar.
   ============================================================================ */
DECLARE @r TABLE (id INT);
DECLARE @u TABLE (idUsuario INT, idEstudiante INT NULL);

DECLARE @hoy DATE = CAST(GETDATE() AS DATE);

-- Calcula la fecha de finalización de la suscripción (un año después).
DECLARE @fechaFinSuscripcion DATE = DATEADD(YEAR, 1, @hoy);

DECLARE @idRolAdmin INT, @idRolEstudiante INT, @idRolCoordinador INT;
DECLARE @idPlanBasico INT, @idPlanInstitucional INT;
DECLARE @idUniversidad INT, @idSede INT, @idSuscripcion INT;
DECLARE @idCarrera INT, @idCursoBD INT, @idCursoProg INT;
DECLARE @idProfMaria INT, @idProfCarlos INT;
DECLARE @idLeccionBD INT, @idLeccionProg INT;
DECLARE @idUsuarioAdmin INT, @idUsuarioEstudiante INT, @idEstudiante INT;
DECLARE @idMatricula INT, @idResennia INT, @idEvaluacion INT, @idBitacora INT;

/* ============================================================================
   2. ROLES
   Crea los roles Administrador, Estudiante y Coordinador si todavía no existen.
   ============================================================================ */
PRINT '=== 2. ROLES ===';

SELECT @idRolAdmin = idRol FROM VidaU.Rol WHERE Nombre = 'Administrador';
IF @idRolAdmin IS NULL
BEGIN
    INSERT INTO @r EXEC VidaU.sp_Rol_Agregar
        @Nombre = 'Administrador',
        @Descripcion = 'Administra la plataforma y modera las reseñas';
    SELECT @idRolAdmin = id FROM @r;
    DELETE FROM @r;
END;

SELECT @idRolEstudiante = idRol FROM VidaU.Rol WHERE Nombre = 'Estudiante';
IF @idRolEstudiante IS NULL
BEGIN
    INSERT INTO @r EXEC VidaU.sp_Rol_Agregar
        @Nombre = 'Estudiante',
        @Descripcion = 'Consulta y publica reseñas';
    SELECT @idRolEstudiante = id FROM @r;
    DELETE FROM @r;
END;

SELECT @idRolCoordinador = idRol FROM VidaU.Rol WHERE Nombre = 'Coordinador';
IF @idRolCoordinador IS NULL
BEGIN
    INSERT INTO @r EXEC VidaU.sp_Rol_Agregar
        @Nombre = 'Coordinador',
        @Descripcion = 'Consulta la analítica de su carrera';
    SELECT @idRolCoordinador = id FROM @r;
    DELETE FROM @r;
END;

/* ============================================================================
   3. PLANES
   Registra los planes de suscripción que puede contratar una universidad.
   ============================================================================ */
PRINT '=== 3. PLANES ===';

SELECT @idPlanBasico = idPlan FROM VidaU.[Plan] WHERE Nombre = 'Plan Básico';
IF @idPlanBasico IS NULL
BEGIN
    INSERT INTO @r EXEC VidaU.sp_Plan_Agregar
        @Nombre = 'Plan Básico',
        @Descripcion = 'Analítica básica por carrera',
        @Monto = 100.00;
    SELECT @idPlanBasico = id FROM @r;
    DELETE FROM @r;
END;

SELECT @idPlanInstitucional = idPlan FROM VidaU.[Plan] WHERE Nombre = 'Plan Institucional';
IF @idPlanInstitucional IS NULL
BEGIN
    INSERT INTO @r EXEC VidaU.sp_Plan_Agregar
        @Nombre = 'Plan Institucional',
        @Descripcion = 'Analítica completa y reportes',
        @Monto = 500.00;
    SELECT @idPlanInstitucional = id FROM @r;
    DELETE FROM @r;
END;

/* ============================================================================
   4. UNIVERSIDAD, SEDE Y SUSCRIPCIÓN
   Crea una universidad de ejemplo, una sede asociada y su suscripción vigente.
   ============================================================================ */
PRINT '=== 4. UNIVERSIDAD, SEDE Y SUSCRIPCIÓN ===';

SELECT @idUniversidad = idUniversidad
FROM VidaU.Universidad
WHERE Correo = 'contacto@ulatina.example';

IF @idUniversidad IS NULL
BEGIN
    INSERT INTO @r EXEC VidaU.sp_Universidad_Agregar
        @Nombre = 'Universidad Latina de Costa Rica',
        @Correo = 'contacto@ulatina.example',
        @Telefono = '2000-0000';
    SELECT @idUniversidad = id FROM @r;
    DELETE FROM @r;
END;

SELECT @idSede = idSede
FROM VidaU.Sede
WHERE idUniversidad = @idUniversidad AND Nombre = 'Sede San Pedro';

IF @idSede IS NULL
BEGIN
    INSERT INTO @r EXEC VidaU.sp_Sede_Agregar
        @idUniversidad = @idUniversidad,
        @Nombre = 'Sede San Pedro',
        @Direccion = 'San Pedro, San José';
    SELECT @idSede = id FROM @r;
    DELETE FROM @r;
END;

SELECT TOP (1) @idSuscripcion = idSuscripcion
FROM VidaU.Suscripcion
WHERE idUniversidad = @idUniversidad AND idPlan = @idPlanInstitucional
ORDER BY idSuscripcion DESC;

IF @idSuscripcion IS NULL
BEGIN
    INSERT INTO @r EXEC VidaU.sp_Suscripcion_Agregar
        @idUniversidad = @idUniversidad,
        @idPlan = @idPlanInstitucional,
        @FechaInicio = @hoy,
        @FechaFin = @fechaFinSuscripcion;
SELECT @idSuscripcion = id FROM @r;
    DELETE FROM @r;
END;

/* ============================================================================
   5. CARRERA, CURSOS Y PROFESORES
   Crea la carrera de ejemplo, dos cursos y dos profesores para relacionarlos
   posteriormente con las lecciones.
   ============================================================================ */
PRINT '=== 5. CARRERA, CURSOS Y PROFESORES ===';

SELECT @idCarrera = idCarrera
FROM VidaU.Carrera
WHERE Nombre = 'Ingeniería en Tecnologías de la Información';

IF @idCarrera IS NULL
BEGIN
    INSERT INTO @r EXEC VidaU.sp_Carrera_Agregar
        @Nombre = 'Ingeniería en Tecnologías de la Información',
        @Descripcion = 'Carrera de ejemplo para las pruebas';
    SELECT @idCarrera = id FROM @r;
    DELETE FROM @r;
END;

SELECT @idCursoBD = idCurso FROM VidaU.Curso WHERE Nombre = 'Bases de Datos II';
IF @idCursoBD IS NULL
BEGIN
    INSERT INTO @r EXEC VidaU.sp_Curso_Agregar
        @Nombre = 'Bases de Datos II',
        @Descripcion = 'Procedimientos almacenados, transacciones y optimización',
        @Creditos = 4;
    SELECT @idCursoBD = id FROM @r;
    DELETE FROM @r;
END;

SELECT @idCursoProg = idCurso FROM VidaU.Curso WHERE Nombre = 'Programación I';
IF @idCursoProg IS NULL
BEGIN
    INSERT INTO @r EXEC VidaU.sp_Curso_Agregar
        @Nombre = 'Programación I',
        @Descripcion = 'Fundamentos de programación',
        @Creditos = 4;
    SELECT @idCursoProg = id FROM @r;
    DELETE FROM @r;
END;

SELECT @idProfMaria = idProfesor
FROM VidaU.Profesor
WHERE Correo = 'maria.rojas@ulatina.example';

IF @idProfMaria IS NULL
BEGIN
    INSERT INTO @r EXEC VidaU.sp_Profesor_Agregar
        @Nombre = 'María',
        @Apellido = 'Rojas',
        @Correo = 'maria.rojas@ulatina.example';
    SELECT @idProfMaria = id FROM @r;
    DELETE FROM @r;
END;

SELECT @idProfCarlos = idProfesor
FROM VidaU.Profesor
WHERE Correo = 'carlos.vargas@ulatina.example';

IF @idProfCarlos IS NULL
BEGIN
    INSERT INTO @r EXEC VidaU.sp_Profesor_Agregar
        @Nombre = 'Carlos',
        @Apellido = 'Vargas',
        @Correo = 'carlos.vargas@ulatina.example';
    SELECT @idProfCarlos = id FROM @r;
    DELETE FROM @r;
END;

/* ============================================================================
   6. RELACIONES ENTRE ENTIDADES
   Registra las relaciones universidad-profesor, sede-carrera y carrera-curso.
   Se verifica cada relación para no insertar parejas duplicadas.
   ============================================================================ */
PRINT '=== 6. RELACIONES ENTRE ENTIDADES ===';

IF NOT EXISTS (SELECT 1 FROM VidaU.Universidad_Profesor
               WHERE idUniversidad = @idUniversidad AND idProfesor = @idProfMaria)
    EXEC VidaU.sp_Universidad_Profesor_Agregar
        @idUniversidad = @idUniversidad, @idProfesor = @idProfMaria;

IF NOT EXISTS (SELECT 1 FROM VidaU.Universidad_Profesor
               WHERE idUniversidad = @idUniversidad AND idProfesor = @idProfCarlos)
    EXEC VidaU.sp_Universidad_Profesor_Agregar
        @idUniversidad = @idUniversidad, @idProfesor = @idProfCarlos;

IF NOT EXISTS (SELECT 1 FROM VidaU.Sede_Carrera
               WHERE idSede = @idSede AND idCarrera = @idCarrera)
    EXEC VidaU.sp_Sede_Carrera_Agregar
        @idSede = @idSede, @idCarrera = @idCarrera;

IF NOT EXISTS (SELECT 1 FROM VidaU.Carrera_Curso
               WHERE idCarrera = @idCarrera AND idCurso = @idCursoBD)
    EXEC VidaU.sp_Carrera_Curso_Agregar
        @idCarrera = @idCarrera, @idCurso = @idCursoBD;

IF NOT EXISTS (SELECT 1 FROM VidaU.Carrera_Curso
               WHERE idCarrera = @idCarrera AND idCurso = @idCursoProg)
    EXEC VidaU.sp_Carrera_Curso_Agregar
        @idCarrera = @idCarrera, @idCurso = @idCursoProg;

/* ============================================================================
   7. LECCIONES
   Crea las lecciones de los cursos y asigna un profesor, horario, aula y cupo.
   ============================================================================ */
PRINT '=== 7. LECCIONES ===';

SELECT @idLeccionBD = idLeccion
FROM VidaU.Leccion
WHERE idCurso = @idCursoBD AND idProfesor = @idProfMaria
  AND Horario = 'Lunes 6:00 pm - 9:00 pm';

IF @idLeccionBD IS NULL
BEGIN
    INSERT INTO @r EXEC VidaU.sp_Leccion_Agregar
        @idCurso = @idCursoBD,
        @idProfesor = @idProfMaria,
        @Horario = 'Lunes 6:00 pm - 9:00 pm',
        @Aula = 'A-101',
        @Cupo = 30;
    SELECT @idLeccionBD = id FROM @r;
    DELETE FROM @r;
END;

SELECT @idLeccionProg = idLeccion
FROM VidaU.Leccion
WHERE idCurso = @idCursoProg AND idProfesor = @idProfCarlos
  AND Horario = 'Miércoles 6:00 pm - 9:00 pm';

IF @idLeccionProg IS NULL
BEGIN
    INSERT INTO @r EXEC VidaU.sp_Leccion_Agregar
        @idCurso = @idCursoProg,
        @idProfesor = @idProfCarlos,
        @Horario = 'Miércoles 6:00 pm - 9:00 pm',
        @Aula = 'B-203',
        @Cupo = 25;
    SELECT @idLeccionProg = id FROM @r;
    DELETE FROM @r;
END;

/* ============================================================================
   8. USUARIOS Y PERFIL DE ESTUDIANTE
   Registra un administrador y un estudiante. El procedimiento de registro crea
   automáticamente Estudiante y Carrera_Estudiante cuando se envían los tres
   parámetros: Carnet, idCarrera y AnnoIngreso.
   ============================================================================ */
PRINT '=== 8. USUARIOS Y ESTUDIANTE ===';

SELECT @idUsuarioAdmin = idUsuario
FROM VidaU.Usuario
WHERE Correo = 'admin@vidau.example';

IF @idUsuarioAdmin IS NULL
BEGIN
    INSERT INTO @u EXEC VidaU.sp_Auth_RegistrarUsuario
        @idRol = @idRolAdmin,
        @Nombre = 'Ana',
        @Apellidos = 'Administradora',
        @Correo = 'admin@vidau.example',
        @Contrasena = 'Admin#2026';
    SELECT @idUsuarioAdmin = idUsuario FROM @u;
    DELETE FROM @u;
END;

SELECT @idUsuarioEstudiante = idUsuario
FROM VidaU.Usuario
WHERE Correo = 'kendall.quesada@vidau.example';

IF @idUsuarioEstudiante IS NULL
BEGIN
    INSERT INTO @u EXEC VidaU.sp_Auth_RegistrarUsuario
        @idRol = @idRolEstudiante,
        @Nombre = 'Kendall',
        @Apellidos = 'Quesada',
        @Correo = 'kendall.quesada@vidau.example',
        @Contrasena = 'Estudiante#2026',
        @Carnet = 'C00001',
        @idCarrera = @idCarrera,
        @AnnoIngreso = 2024;
    SELECT @idUsuarioEstudiante = idUsuario, @idEstudiante = idEstudiante FROM @u;
    DELETE FROM @u;
END
ELSE
BEGIN
    SELECT @idEstudiante = idEstudiante
    FROM VidaU.Estudiante
    WHERE idUsuario = @idUsuarioEstudiante;
END;

/* ============================================================================
   9. MATRÍCULA, RESEÑA Y EVALUACIONES
   Registra la matrícula del estudiante, una reseña visible y tres evaluaciones.
   La reseña es anónima y corresponde a la lección de Bases de Datos II.
   ============================================================================ */
PRINT '=== 9. MATRÍCULA, RESEÑA Y EVALUACIONES ===';

SELECT TOP (1) @idMatricula = idMatricula
FROM VidaU.Matricula
WHERE idEstudiante = @idEstudiante
ORDER BY idMatricula DESC;

IF @idMatricula IS NULL
BEGIN
    INSERT INTO @r EXEC VidaU.sp_Matricula_Agregar
        @idEstudiante = @idEstudiante;
    SELECT @idMatricula = id FROM @r;
    DELETE FROM @r;
END;

SELECT @idResennia = idResennia
FROM VidaU.Resennia
WHERE idLeccion = @idLeccionBD AND idEstudiante = @idEstudiante;

IF @idResennia IS NULL
BEGIN
    INSERT INTO @r EXEC VidaU.sp_Resennia_Agregar
        @idLeccion = @idLeccionBD,
        @idEstudiante = @idEstudiante,
        @Estado = 'Visible',
        @EsAnonima = 1;
    SELECT @idResennia = id FROM @r;
    DELETE FROM @r;
END;

IF NOT EXISTS (SELECT 1 FROM VidaU.Evaluacion WHERE idResennia = @idResennia)
BEGIN
    INSERT INTO @r EXEC VidaU.sp_Evaluacion_Agregar
        @idResennia = @idResennia,
        @Calificacion = 4.5,
        @Comentario = 'Explica con claridad';
    DELETE FROM @r;

    INSERT INTO @r EXEC VidaU.sp_Evaluacion_Agregar
        @idResennia = @idResennia,
        @Calificacion = 5.0,
        @Comentario = 'Muy buena disponibilidad';
    DELETE FROM @r;

    INSERT INTO @r EXEC VidaU.sp_Evaluacion_Agregar
        @idResennia = @idResennia,
        @Calificacion = 4.0,
        @Comentario = 'Exigente pero justo';
    DELETE FROM @r;
END;

PRINT 'Datos semilla verificados/cargados correctamente.';

/* ============================================================================
   10. PRUEBAS DE CONSULTA DE LOS PROCEDIMIENTOS
   Ejecuta los procedimientos Consultar y ConsultarPorId de las entidades.
   Cada bloque muestra los registros existentes y luego el registro de ejemplo.
   ============================================================================ */

PRINT '=== PRUEBA 1: CONSULTAR ROLES ===';
EXEC VidaU.sp_Rol_Consultar;
EXEC VidaU.sp_Rol_ConsultarPorId @idRol = @idRolAdmin;

PRINT '=== PRUEBA 2: CONSULTAR PLANES ===';
EXEC VidaU.sp_Plan_Consultar;
EXEC VidaU.sp_Plan_ConsultarPorId @idPlan = @idPlanInstitucional;

PRINT '=== PRUEBA 3: CONSULTAR UNIVERSIDADES ===';
EXEC VidaU.sp_Universidad_Consultar;
EXEC VidaU.sp_Universidad_ConsultarPorId @idUniversidad = @idUniversidad;

PRINT '=== PRUEBA 4: CONSULTAR CARRERAS ===';
-- Consulta todas las carreras registradas en el sistema.
-- También consulta una carrera específica mediante su identificador.
EXEC VidaU.sp_Carrera_Consultar;
EXEC VidaU.sp_Carrera_ConsultarPorId @idCarrera = @idCarrera;

PRINT '=== PRUEBA 5: CONSULTAR CURSOS ===';
EXEC VidaU.sp_Curso_Consultar;
EXEC VidaU.sp_Curso_ConsultarPorId @idCurso = @idCursoBD;

PRINT '=== PRUEBA 6: CONSULTAR PROFESORES ===';
EXEC VidaU.sp_Profesor_Consultar;
EXEC VidaU.sp_Profesor_ConsultarPorId @idProfesor = @idProfMaria;

PRINT '=== PRUEBA 7: CONSULTAR SEDES ===';
EXEC VidaU.sp_Sede_Consultar;
EXEC VidaU.sp_Sede_ConsultarPorId @idSede = @idSede;

PRINT '=== PRUEBA 8: CONSULTAR SUSCRIPCIONES ===';
EXEC VidaU.sp_Suscripcion_Consultar;
EXEC VidaU.sp_Suscripcion_ConsultarPorId @idSuscripcion = @idSuscripcion;

PRINT '=== PRUEBA 9: CONSULTAR USUARIOS ===';
-- El procedimiento devuelve datos generales y no expone el hash de la contraseña.
EXEC VidaU.sp_Usuario_Consultar;
EXEC VidaU.sp_Usuario_ConsultarPorId @idUsuario = @idUsuarioEstudiante;

PRINT '=== PRUEBA 10: CONSULTAR ESTUDIANTES ===';
EXEC VidaU.sp_Estudiante_Consultar;
EXEC VidaU.sp_Estudiante_ConsultarPorId @idEstudiante = @idEstudiante;

PRINT '=== PRUEBA 11: CONSULTAR LECCIONES ===';
EXEC VidaU.sp_Leccion_Consultar;
EXEC VidaU.sp_Leccion_ConsultarPorId @idLeccion = @idLeccionBD;

PRINT '=== PRUEBA 12: CONSULTAR MATRÍCULAS ===';
EXEC VidaU.sp_Matricula_Consultar;
EXEC VidaU.sp_Matricula_ConsultarPorId @idMatricula = @idMatricula;

PRINT '=== PRUEBA 13: CONSULTAR RESEÑAS ===';
EXEC VidaU.sp_Resennia_Consultar;
EXEC VidaU.sp_Resennia_ConsultarPorId @idResennia = @idResennia;

PRINT '=== PRUEBA 14: CONSULTAR EVALUACIONES ===';
EXEC VidaU.sp_Evaluacion_Consultar @idResennia = @idResennia;
SELECT TOP (1) @idEvaluacion = idEvaluacion
FROM VidaU.Evaluacion
WHERE idResennia = @idResennia
ORDER BY idEvaluacion;
EXEC VidaU.sp_Evaluacion_ConsultarPorId @idEvaluacion = @idEvaluacion;

PRINT '=== PRUEBA 15: CONSULTAR RELACIÓN UNIVERSIDAD-PROFESOR ===';
EXEC VidaU.sp_Universidad_Profesor_Consultar
    @idUniversidad = @idUniversidad, @idProfesor = @idProfMaria;
EXEC VidaU.sp_Universidad_Profesor_ConsultarPorId
    @idUniversidad = @idUniversidad, @idProfesor = @idProfMaria;

PRINT '=== PRUEBA 16: CONSULTAR RELACIÓN SEDE-CARRERA ===';
EXEC VidaU.sp_Sede_Carrera_Consultar
    @idSede = @idSede, @idCarrera = @idCarrera;
EXEC VidaU.sp_Sede_Carrera_ConsultarPorId
    @idSede = @idSede, @idCarrera = @idCarrera;

PRINT '=== PRUEBA 17: CONSULTAR RELACIÓN CARRERA-CURSO ===';
EXEC VidaU.sp_Carrera_Curso_Consultar
    @idCarrera = @idCarrera, @idCurso = @idCursoBD;
EXEC VidaU.sp_Carrera_Curso_ConsultarPorId
    @idCarrera = @idCarrera, @idCurso = @idCursoBD;

PRINT '=== PRUEBA 18: CONSULTAR RELACIÓN CARRERA-ESTUDIANTE ===';
EXEC VidaU.sp_Carrera_Estudiante_Consultar
    @idCarrera = @idCarrera, @idEstudiante = @idEstudiante;
EXEC VidaU.sp_Carrera_Estudiante_ConsultarPorId
    @idCarrera = @idCarrera, @idEstudiante = @idEstudiante;

/* ============================================================================
   11. PRUEBAS DE AUTENTICACIÓN
   Comprueba el registro de intentos fallidos, el inicio de sesión correcto,
   la consulta del perfil, el historial y el cierre de sesión.
   ============================================================================ */
PRINT '=== PRUEBA 19: LOGIN CON CONTRASEÑA INCORRECTA ===';
BEGIN TRY
    EXEC VidaU.sp_Auth_Login
        @Correo = 'kendall.quesada@vidau.example',
        @Contrasena = 'ClaveIncorrecta#2026';
    PRINT 'ADVERTENCIA: se aceptó una contraseña incorrecta.';
END TRY
BEGIN CATCH
    SELECT ERROR_NUMBER() AS codigo_error, ERROR_MESSAGE() AS mensaje;
    -- Se espera el error 50030: correo o contraseña incorrectos.
END CATCH;

PRINT '=== PRUEBA 20: LOGIN CORRECTO ===';
EXEC VidaU.sp_Auth_Login
    @Correo = 'kendall.quesada@vidau.example',
    @Contrasena = 'Estudiante#2026';

PRINT '=== PRUEBA 21: OBTENER PERFIL DEL ESTUDIANTE ===';
-- Devuelve dos conjuntos: información del usuario/perfil y sus universidades,
-- sedes y carreras relacionadas.
EXEC VidaU.sp_Auth_ObtenerPerfil @idUsuario = @idUsuarioEstudiante;

PRINT '=== PRUEBA 22: INTENTAR REGISTRAR UNA RESEÑA DUPLICADA ===';
BEGIN TRY
    EXEC VidaU.sp_Resennia_Agregar
        @idLeccion = @idLeccionBD,
        @idEstudiante = @idEstudiante;
    PRINT 'ADVERTENCIA: se permitió una reseña duplicada.';
END TRY
BEGIN CATCH
    SELECT ERROR_NUMBER() AS codigo_error, ERROR_MESSAGE() AS mensaje;
    -- Se espera el error 50023: una reseña por estudiante por lección.
END CATCH;

PRINT '=== PRUEBA 23: CONSULTAR HISTORIAL DE AUTENTICACIÓN ===';
EXEC VidaU.sp_Auth_ConsultarHistorial
    @idUsuario = @idUsuarioEstudiante,
    @Top = 20;

PRINT '=== PRUEBA 24: CERRAR SESIÓN ===';
EXEC VidaU.sp_Auth_Logout @idUsuario = @idUsuarioEstudiante;

PRINT '=== PRUEBA 25: REGISTRAR Y CONSULTAR UN EVENTO DE BITÁCORA ===';
-- Inserta un evento de prueba mediante el procedimiento y recupera su identificador.
DECLARE @b TABLE (id INT);
INSERT INTO @b EXEC VidaU.sp_Bitacora_Agregar
    @idUsuario = @idUsuarioEstudiante,
    @Accion = 'PruebaManual',
    @TablaAfectada = 'Prueba',
    @Descripcion = 'Evento generado desde el script de datos semilla y pruebas.';
SELECT @idBitacora = id FROM @b;
EXEC VidaU.sp_Bitacora_Consultar;
EXEC VidaU.sp_Bitacora_ConsultarPorId @idBitacora = @idBitacora;

PRINT '=== PRUEBA 26: PROMEDIO DE CALIFICACIONES DE LA RESEÑA ===';
-- No existe sp_Evaluacion_PromedioResennia en los archivos 01 al 20.
-- El promedio se obtiene con una consulta sobre las evaluaciones registradas.
SELECT idResennia,
       COUNT(*) AS TotalEvaluaciones,
       CAST(AVG(Calificacion) AS DECIMAL(3,2)) AS CalificacionPromedio
FROM VidaU.Evaluacion
WHERE idResennia = @idResennia
GROUP BY idResennia;

PRINT '=== PRUEBA 27: VIGENCIA DE LA SUSCRIPCIÓN ===';
-- Este procedimiento se crea en Funciones.sql; se ejecuta solo si está instalado.
IF OBJECT_ID('VidaU.sp_Suscripcion_ConsultarVigencia', 'P') IS NOT NULL
    EXEC VidaU.sp_Suscripcion_ConsultarVigencia @idUniversidad = @idUniversidad;
ELSE
    PRINT 'No está instalado sp_Suscripcion_ConsultarVigencia. Ejecute Funciones.sql.';

PRINT '=== PRUEBA 28: REPUTACIÓN DEL PROFESOR ===';
-- Este procedimiento se crea en Funciones.sql; resume reseñas visibles y evaluaciones.
IF OBJECT_ID('VidaU.sp_Profesor_ConsultarReputacion', 'P') IS NOT NULL
    EXEC VidaU.sp_Profesor_ConsultarReputacion @idProfesor = @idProfMaria;
ELSE
    PRINT 'No está instalado sp_Profesor_ConsultarReputacion. Ejecute Funciones.sql.';

/* ============================================================================
   12. 
   Cuenta los registros de las tablas principales para comprobar que los datos
   de ejemplo quedaron almacenados.
   ============================================================================ */
PRINT '=== RESUMEN FINAL: CANTIDAD DE REGISTROS ===';

SELECT 'Rol' AS Tabla, COUNT(*) AS TotalRegistros FROM VidaU.Rol
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
UNION ALL SELECT 'Bitacora', COUNT(*) FROM VidaU.Bitacora
UNION ALL SELECT 'Universidad_Profesor', COUNT(*) FROM VidaU.Universidad_Profesor
UNION ALL SELECT 'Sede_Carrera', COUNT(*) FROM VidaU.Sede_Carrera
UNION ALL SELECT 'Carrera_Curso', COUNT(*) FROM VidaU.Carrera_Curso
UNION ALL SELECT 'Carrera_Estudiante', COUNT(*) FROM VidaU.Carrera_Estudiante
ORDER BY Tabla;

PRINT '=== FIN DEL SCRIPT DE DATOS SEMILLA Y PRUEBAS ===';
GO
