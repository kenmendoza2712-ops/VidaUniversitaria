CREATE DATABASE VidaUniversitariaDB
GO
 

-- Profesor: docente que imparte lecciones. Se relaciona con Universidad mediante la
-- tabla puente Universidad_Profesor (un profesor puede dar clases en varias universidades).
-- Es referenciada por Universidad_Profesor y Leccion.
CREATE TABLE VidaU.Profesor (
    idProfesor      INT IDENTITY(1,1) CONSTRAINT PK_Profesor PRIMARY KEY, -- TIPO IDENTITY PARA QUE GENERE AUTOMATICAMENTE EL IDENTIFICADOR
    Nombre          VARCHAR(100) NOT NULL,
    Apellido        VARCHAR(100) NOT NULL,
    Correo          VARCHAR(150) NOT NULL,
    CONSTRAINT UQ_Profesor_Correo UNIQUE (Correo) -- UNIQUE NO PERMITE VALORES REPETIDOS, EJEMPLO DOS PROFESORES CON EL MISMO CORREO
);
GO