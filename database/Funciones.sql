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

/* ============================================================
   Función: VidaU.fn_Suscripcion_Vigente
   Sección: Funcion escalar: suscripcion vigente
   Función: Indica si una universidad tiene una suscripcion vigente hoy.
            DEVUELVE 1 SI HAY AL MENOS UNA SUSCRIPCION 'Activa' CUYO RANGO DE FECHAS CUBRE EL DIA DE HOY; 0 SI NO.
   Parámetros: @idUniversidad INT
   ============================================================ */
CREATE OR ALTER FUNCTION VidaU.fn_Suscripcion_Vigente
(
    @idUniversidad INT
)
RETURNS BIT
AS
BEGIN
    DECLARE @Hoy DATE = CAST(GETDATE() AS DATE);

    RETURN CASE WHEN EXISTS (SELECT 1
                             FROM VidaU.Suscripcion su
                             WHERE su.idUniversidad = @idUniversidad
                               AND su.Estado = 'Activa'
                               AND su.FechaInicio <= @Hoy
                               AND (su.FechaFin IS NULL OR su.FechaFin >= @Hoy))
                THEN 1 ELSE 0 END;
END
GO

/* ============================================================
   Función: VidaU.fn_Profesor_Reputacion
   Sección: Funcion de tabla: reputacion de un profesor
   Función: Resume la reputacion de un profesor: total de resennias VISIBLES de sus lecciones,
            total de evaluaciones y calificacion promedio. SIEMPRE DEVUELVE UNA FILA
            (PROMEDIO NULL SI NO HAY EVALUACIONES).
   Parámetros: @idProfesor INT
 
   ============================================================ */
CREATE OR ALTER FUNCTION VidaU.fn_Profesor_Reputacion
(
    @idProfesor INT
)
RETURNS TABLE
AS
RETURN
(
    SELECT @idProfesor                               AS idProfesor,
           COUNT(DISTINCT r.idResennia)              AS TotalResennias,
           COUNT(e.idEvaluacion)                     AS TotalEvaluaciones,
           CAST(AVG(e.Calificacion) AS DECIMAL(3,2)) AS CalificacionPromedio
    FROM VidaU.Leccion l
    INNER JOIN VidaU.Resennia r
            ON r.idLeccion = l.idLeccion
           AND r.Estado = 'Visible'
    LEFT JOIN VidaU.Evaluacion e
           ON e.idResennia = r.idResennia
    WHERE l.idProfesor = @idProfesor
);
GO

/* ============================================================
   Procedimiento almacenado: VidaU.sp_Suscripcion_ConsultarVigencia
   Sección: Reporte de vigencia de suscripciones
   Función: Devuelve cada universidad (o solo la indicada) con SuscripcionVigente = 1/0.
            USA fn_Suscripcion_Vigente. LANZA 50007 SI LA UNIVERSIDAD INDICADA NO EXISTE.
            SOLO LECTURA: NO NECESITA TRANSACCION EXPLICITA
   Parámetros: @idUniversidad INT = NULL
  
   ============================================================ */
CREATE OR ALTER PROCEDURE VidaU.sp_Suscripcion_ConsultarVigencia
    @idUniversidad INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @idUniversidad IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM VidaU.Universidad WHERE idUniversidad = @idUniversidad)
        THROW 50007, 'La universidad indicada no existe.', 1;

    SELECT idUniversidad,
           Nombre,
           Estado,
           VidaU.fn_Suscripcion_Vigente(idUniversidad) AS SuscripcionVigente -- 1 = VIGENTE HOY, 0 = NO
    FROM VidaU.Universidad
    WHERE (@idUniversidad IS NULL OR idUniversidad = @idUniversidad)
    ORDER BY idUniversidad;
END
GO

/* ============================================================
   Procedimiento almacenado: VidaU.sp_Profesor_ConsultarReputacion
   Sección: Reporte de reputacion de profesores
   Función: Devuelve la reputacion de un profesor, o de todos si @idProfesor es NULL,
            ORDENADOS POR CALIFICACION PROMEDIO. USA fn_Profesor_Reputacion.
            LANZA 50002 SI EL PROFESOR INDICADO NO EXISTE.
            SOLO LECTURA: NO NECESITA TRANSACCION EXPLICITA
   Parámetros: @idProfesor INT = NULL
  
   ============================================================ */
CREATE OR ALTER PROCEDURE VidaU.sp_Profesor_ConsultarReputacion
    @idProfesor INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @idProfesor IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM VidaU.Profesor WHERE idProfesor = @idProfesor)
        THROW 50002, 'El profesor indicado no existe.', 1;

    SELECT p.idProfesor,
           p.Nombre,
           p.Apellido,
           rep.TotalResennias,
           rep.TotalEvaluaciones,
           rep.CalificacionPromedio
    FROM VidaU.Profesor p
    CROSS APPLY VidaU.fn_Profesor_Reputacion(p.idProfesor) rep
    WHERE (@idProfesor IS NULL OR p.idProfesor = @idProfesor)
    ORDER BY rep.CalificacionPromedio DESC, p.idProfesor;
END
GO

-- VERIFICACION: debe listar 3 funciones (2 nuevas + fn_Auth_IntentosFallidos)
SELECT o.name AS funcion, o.type_desc AS tipo
FROM sys.objects o
WHERE o.schema_id = SCHEMA_ID('VidaU') AND o.type IN ('FN','IF','TF')
ORDER BY o.name;
GO

-- PRUEBAS MANUALES
EXEC VidaU.sp_Suscripcion_ConsultarVigencia;
EXEC VidaU.sp_Suscripcion_ConsultarVigencia @idUniversidad = 1;
EXEC VidaU.sp_Profesor_ConsultarReputacion;
EXEC VidaU.sp_Profesor_ConsultarReputacion @idProfesor = 1;