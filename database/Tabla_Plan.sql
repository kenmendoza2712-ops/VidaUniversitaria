CREATE DATABASE VidaUniversitariaDB
GO
 
 -- Plan: catálogo de planes de suscripción que una universidad puede contratar
-- (ej. Plan Básico, Plan Institucional). No depende de ninguna otra tabla;
-- es referenciada por Suscripcion.
-- PLAN ES PALABRA RESERVADA EN SQL SERVER, POR ESO SE ESCRIBE ENTRE CORCHETES [Plan]
CREATE TABLE VidaU.[Plan] (
    idPlan          INT IDENTITY(1,1) CONSTRAINT PK_Plan PRIMARY KEY, -- TIPO IDENTITY PARA QUE GENERE AUTOMATICAMENTE EL IDENTIFICADOR
    Nombre          VARCHAR(100) NOT NULL,
    Descripcion     VARCHAR(300) NULL,
    Monto           DECIMAL(10,2) NOT NULL,
    CONSTRAINT CK_Plan_Monto CHECK (Monto >= 0)  -- CHECK VERIFICA QUE EL MONTO SEA MAYOR O IGUAL A 0
);
GO