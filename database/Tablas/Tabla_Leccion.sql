CREATE DATABASE VidaUniversitariaDB
GO

-- Leccion: combinación concreta de un curso + un profesor + un horario.
-- Es lo que un estudiante reseña (antes se llamaba Imparticion).
-- FK idCurso -> Curso. FK idProfesor -> Profesor.
-- Es referenciada por Resennia.
CREATE TABLE VidaU.Leccion (
    idLeccion       INT IDENTITY(1,1) CONSTRAINT PK_Leccion PRIMARY KEY, -- TIPO IDENTITY PARA QUE GENERE AUTOMATICAMENTE EL IDENTIFICADOR
    idCurso         INT NOT NULL,
    idProfesor      INT NOT NULL,
    Horario         VARCHAR(100) NOT NULL,
    Aula            VARCHAR(50)  NULL,
    Cupo            INT NOT NULL,
    CONSTRAINT FK_Leccion_Curso FOREIGN KEY (idCurso) -- CONECTA CON LA TABLA CURSO
        REFERENCES VidaU.Curso(idCurso),
    CONSTRAINT FK_Leccion_Profesor FOREIGN KEY (idProfesor) -- CONECTA CON LA TABLA PROFESOR
        REFERENCES VidaU.Profesor(idProfesor),
    CONSTRAINT CK_Leccion_Cupo CHECK (Cupo > 0) -- El cupo total de la leccion no puede ser cero ni negativo 
);
GO