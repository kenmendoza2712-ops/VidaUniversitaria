CREATE DATABASE VidaUniversitariaDB
GO

-- Carrera_Curso: una carrera contiene varios cursos y un curso puede
-- pertenecer a varias carreras.
CREATE TABLE VidaU.Carrera_Curso (
    idCarrera       INT NOT NULL,
    idCurso         INT NOT NULL,
    CONSTRAINT PK_Carrera_Curso PRIMARY KEY (idCarrera, idCurso), -- PK COMPUESTA: LA MISMA PAREJA NO SE PUEDE REPETIR
    CONSTRAINT FK_CarrCurso_Carrera FOREIGN KEY (idCarrera) -- CONECTA LA TABLA CARRERA
        REFERENCES VidaU.Carrera(idCarrera),
    CONSTRAINT FK_CarrCurso_Curso FOREIGN KEY (idCurso) -- CONECTA LA TABLA CURSO
        REFERENCES VidaU.Curso(idCurso)
);
GO