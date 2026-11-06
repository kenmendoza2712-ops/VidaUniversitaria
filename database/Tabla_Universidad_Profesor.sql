CREATE DATABASE VidaUniversitariaDB
GO

/*
   TABLAS PUENTE (resuelven las relaciones muchos a muchos del modelo)
   Cada una usa como PK la combinación de sus dos FK, así no se puede
   registrar dos veces la misma pareja.
*/
 
-- Universidad_Profesor: un profesor puede trabajar en varias universidades
-- y una universidad tiene muchos profesores.
CREATE TABLE VidaU.Universidad_Profesor (
    idUniversidad   INT NOT NULL,
    idProfesor      INT NOT NULL,
    CONSTRAINT PK_Universidad_Profesor PRIMARY KEY (idUniversidad, idProfesor), -- PK COMPUESTA: LA MISMA PAREJA NO SE PUEDE REPETIR
    CONSTRAINT FK_UnivProf_Universidad FOREIGN KEY (idUniversidad) -- CONECTA LA TABLA UNIVERSIDAD
        REFERENCES VidaU.Universidad(idUniversidad),
    CONSTRAINT FK_UnivProf_Profesor FOREIGN KEY (idProfesor) -- CONECTA LA TABLA PROFESOR
        REFERENCES VidaU.Profesor(idProfesor)
);
GO