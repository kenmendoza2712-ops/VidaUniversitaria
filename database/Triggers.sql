
-- Vida Universitaria: TRIGGERS 
-- Contenido: 2 triggers (esquema VidaU).
--   trg_Suscripcion_ValidarTraslape, regla de negocio (no garantizable con CHECK)
--   trg_Resennia_AuditarEstado, auditoria en Bitacora
-- ============================================================================
USE VidaUniversitariaDB
GO

/* ============================================================
   Trigger: VidaU.trg_Suscripcion_ValidarTraslape
   Sección: Regla de negocio: suscripciones sin traslape
   Función: Una universidad no puede tener dos suscripciones 'Activa' con fechas traslapadas
            (FechaFin NULL = SIN FIN). COMPARA FILAS DISTINTAS, POR ESO UN CHECK NO PUEDE GARANTIZARLO.
            SE DISPARA TAMBIEN ANTE UN INSERT/UPDATE DIRECTO. LANZA 50040.
   ============================================================ */
CREATE OR ALTER TRIGGER VidaU.trg_Suscripcion_ValidarTraslape
ON VidaU.Suscripcion
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT (UPDATE(idUniversidad) OR UPDATE(Estado) OR UPDATE(FechaInicio) OR UPDATE(FechaFin))
        RETURN;

    IF EXISTS (SELECT 1
               FROM inserted i
               INNER JOIN VidaU.Suscripcion s
                       ON s.idUniversidad = i.idUniversidad
                      AND s.idSuscripcion <> i.idSuscripcion
               WHERE i.Estado = 'Activa'
                 AND s.Estado = 'Activa'
                 AND i.FechaInicio <= ISNULL(s.FechaFin, CAST('9999-12-31' AS DATE))
                 AND s.FechaInicio <= ISNULL(i.FechaFin, CAST('9999-12-31' AS DATE)))
    BEGIN
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION; -- DESHACE LA OPERACION QUE DISPARO EL TRIGGER
        THROW 50040, 'La universidad ya tiene una suscripcion activa en ese rango de fechas.', 1;
    END
END
GO

/* ============================================================
   Trigger: VidaU.trg_Resennia_AuditarEstado
   Sección: Auditoria: cambio de estado de una resennia
   Función: Cuando cambia el Estado de una resennia (Visible/Oculta/EnRevision) registra en Bitacora
            EL CAMBIO ANTERIOR -> NUEVO, A NOMBRE DEL USUARIO AUTOR DE LA RESENNIA.
   ============================================================ */
CREATE OR ALTER TRIGGER VidaU.trg_Resennia_AuditarEstado
ON VidaU.Resennia
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT UPDATE(Estado)
        RETURN;

    INSERT INTO VidaU.Bitacora (idUsuario, Accion, TablaAfectada, Descripcion)
    SELECT e.idUsuario,
           'CambioEstadoResennia',
           'Resennia',
           CONCAT('Resennia #', i.idResennia, ': estado ', d.Estado, ' -> ', i.Estado, '.')
    FROM inserted i
    INNER JOIN deleted d ON d.idResennia = i.idResennia
    INNER JOIN VidaU.Estudiante e ON e.idEstudiante = i.idEstudiante
    WHERE i.Estado <> d.Estado;
END
GO

-- VERIFICACION: debe listar 2 triggers
SELECT o.name AS trigger_nombre, OBJECT_NAME(o.parent_object_id) AS tabla
FROM sys.objects o
WHERE o.schema_id = SCHEMA_ID('VidaU') AND o.type = 'TR'
ORDER BY o.name;
GO

-- PRUEBAS MANUALES 
-- Trigger 1: la segunda suscripcion activa traslapada debe fallar con el error 50040
  -- EXEC VidaU.sp_Suscripcion_Agregar @idUniversidad = 1, @idPlan = 1, @FechaInicio = '2026-01-01', @FechaFin = '2026-12-31';
  -- EXEC VidaU.sp_Suscripcion_Agregar @idUniversidad = 1, @idPlan = 1, @FechaInicio = '2026-06-01', @FechaFin = NULL; -- ERROR 50040
-- Trigger 2: cambiar el estado de una resennia y revisar Bitacora
--   EXEC VidaU.sp_Resennia_Actualizar @idResennia = 1, @idLeccion = <igual>, @idEstudiante = <igual>, @Estado = 'Visible', @EsAnonima = 1;
--   SELECT TOP 5 * FROM VidaU.Bitacora WHERE Accion = 'CambioEstadoResennia' ORDER BY idBitacora DESC;