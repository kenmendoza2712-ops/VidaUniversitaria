CREATE DATABASE VidaUniversitariaDB
GO
 

/* 
   TABLAS DE PRIMER NIVEL (dependen de las anteriores)
 */
 
-- Sede: campus o sucursal física de una universidad. Una universidad puede
-- tener varias sedes. FK idUniversidad -> Universidad.
-- Se relaciona con Carrera mediante la tabla puente Sede_Carrera.
CREATE TABLE VidaU.Sede (
    idSede          INT IDENTITY(1,1) CONSTRAINT PK_Sede PRIMARY KEY, -- TIPO IDENTITY PARA QUE GENERE AUTOMATICAMENTE EL IDENTIFICADOR
    idUniversidad   INT NOT NULL,
    Nombre          VARCHAR(150) NOT NULL,
    Estado          VARCHAR(20)  NOT NULL CONSTRAINT DF_Sede_Estado DEFAULT 'Activa', -- SI NO SE INGRESA EL ESTADO, LO DEFINE COMO ACTIVA.
    Direccion       VARCHAR(250) NULL,
    CONSTRAINT FK_Sede_Universidad FOREIGN KEY (idUniversidad) -- CONECTA LA TABLA UNIVERSIDAD
        REFERENCES VidaU.Universidad(idUniversidad),
    CONSTRAINT CK_Sede_Estado CHECK (Estado IN ('Activa','Inactiva')) -- CHECK VALIDA QUE ESTE ACTIVA O INACTIVA
);
GO