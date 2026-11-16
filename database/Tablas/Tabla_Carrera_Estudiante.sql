CREATE DATABASE VidaUniversitariaDB
GO

 
-- Carrera_Estudiante: un estudiante puede cursar varias carreras y una
-- carrera tiene muchos estudiantes.
CREATE TABLE VidaU.Carrera_Estudiante (
    idCarrera       INT NOT NULL,
    idEstudiante    INT NOT NULL,
    CONSTRAINT PK_Carrera_Estudiante PRIMARY KEY (idCarrera, idEstudiante), -- PK COMPUESTA: LA MISMA PAREJA NO SE PUEDE REPETIR
    CONSTRAINT FK_CarrEst_Carrera FOREIGN KEY (idCarrera) -- CONECTA LA TABLA CARRERA
        REFERENCES VidaU.Carrera(idCarrera),
    CONSTRAINT FK_CarrEst_Estudiante FOREIGN KEY (idEstudiante) -- CONECTA LA TABLA ESTUDIANTE
        REFERENCES VidaU.Estudiante(idEstudiante)
);
GO