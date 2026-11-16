CREATE DATABASE VidaUniversitariaDB
GO

 
-- Sede_Carrera: una sede ofrece varias carreras y una carrera se ofrece
-- en varias sedes.
CREATE TABLE VidaU.Sede_Carrera (
    idSede          INT NOT NULL,
    idCarrera       INT NOT NULL,
    CONSTRAINT PK_Sede_Carrera PRIMARY KEY (idSede, idCarrera), -- PK COMPUESTA: LA MISMA PAREJA NO SE PUEDE REPETIR
    CONSTRAINT FK_SedeCarr_Sede FOREIGN KEY (idSede) -- CONECTA LA TABLA SEDE
        REFERENCES VidaU.Sede(idSede),
    CONSTRAINT FK_SedeCarr_Carrera FOREIGN KEY (idCarrera) -- CONECTA LA TABLA CARRERA
        REFERENCES VidaU.Carrera(idCarrera)
);
GO