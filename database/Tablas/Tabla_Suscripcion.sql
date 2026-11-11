CREATE DATABASE VidaUniversitariaDB
GO
 

-- Suscripcion: contrato activo entre una universidad y un plan de la
-- plataforma. Permite llevar control de pagos/vigencia.
-- FK idUniversidad -> Universidad. FK idPlan -> Plan.
CREATE TABLE VidaU.Suscripcion (
    idSuscripcion   INT IDENTITY(1,1) CONSTRAINT PK_Suscripcion PRIMARY KEY,  -- TIPO IDENTITY PARA QUE GENERE AUTOMATICAMENTE EL IDENTIFICADOR
    idUniversidad   INT NOT NULL,
    idPlan          INT NOT NULL,
    Estado          VARCHAR(20) NOT NULL CONSTRAINT DF_Suscripcion_Estado DEFAULT 'Activa', -- SI NO SE INGRESA EL ESTADO, LO DEFINE COMO ACTIVA.
    FechaInicio     DATE NOT NULL,
    FechaFin        DATE NULL,
    CONSTRAINT FK_Suscripcion_Universidad FOREIGN KEY (idUniversidad) -- CONECTA LA TABLA UNIVERSIDAD
        REFERENCES VidaU.Universidad(idUniversidad),
    CONSTRAINT FK_Suscripcion_Plan FOREIGN KEY (idPlan) -- CONECTA LA TABLA PLAN
        REFERENCES VidaU.[Plan](idPlan),
    CONSTRAINT CK_Suscripcion_Estado CHECK (Estado IN ('Activa','Inactiva','Vencida')), -- CHECK, VERIFICA QUE EL ESTADO SEA ACTIVA, INACTIVA O VENCIDA.
    CONSTRAINT CK_Suscripcion_Fechas CHECK (FechaFin IS NULL OR FechaFin >= FechaInicio) -- CHECK, SI LA FECHA DE FINALIZACION ES NULA O MAYOR O IGUAL A LA FECHA DE INICIO.
);
GO