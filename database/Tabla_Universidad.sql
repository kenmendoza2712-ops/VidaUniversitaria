CREATE DATABASE VidaUniversitariaDB
GO


-- Universidad: institución que usa la plataforma. Es la entidad raíz de la
-- que dependen sedes, profesores y suscripciones.
-- Es referenciada por Sede, Suscripcion y Universidad_Profesor.
CREATE TABLE VidaU.Universidad (
    idUniversidad   INT IDENTITY(1,1) CONSTRAINT PK_Universidad PRIMARY KEY, -- TIPO IDENTITY PARA QUE GENERE AUTOMATICAMENTE EL IDENTIFICADOR
    Nombre          VARCHAR(150) NOT NULL,
    Correo          VARCHAR(150) NOT NULL,
    Estado          VARCHAR(20)  NOT NULL CONSTRAINT DF_Universidad_Estado DEFAULT 'Activa', -- VALOR AUTOMATICO "ACTIVA"
    Telefono        VARCHAR(20)  NULL,
    CONSTRAINT UQ_Universidad_Correo UNIQUE (Correo), -- UNIQUE NO PERMITE VALORES REPETIDOS, EJEMPLO DOS UNIVERSIDADES CON EL MISMO CORREO
    CONSTRAINT CK_Universidad_Estado CHECK (Estado IN ('Activa','Inactiva')) -- CHECK VALIDA QUE ESTE ACTIVA O INACTIVA
);
GO
 