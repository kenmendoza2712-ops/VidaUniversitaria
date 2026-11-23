USE VidaUniversitariaDB;
GO

GRANT EXECUTE ON OBJECT::VidaU.sp_Universidad_Consultar TO app_user;
GO

-- Permite al usuario de solo lectura consultar los reportes autorizados.
GRANT EXECUTE ON OBJECT::VidaU.sp_Suscripcion_ConsultarVigencia TO app_readonly;
GO

GRANT EXECUTE ON OBJECT::VidaU.sp_Profesor_ConsultarReputacion TO app_readonly;
GO