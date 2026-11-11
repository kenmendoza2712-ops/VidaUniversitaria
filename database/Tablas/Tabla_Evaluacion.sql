CREATE DATABASE VidaUniversitariaDB
GO

/*
   TABLAS DE CUARTO NIVEL
*/
 
-- Evaluacion: calificación detallada dentro de una reseña, con su propio comentario.
-- Una reseña puede tener varias evaluaciones; el promedio de sus calificaciones es
-- la calificación general de la reseña.
-- FK idResennia -> Resennia.
CREATE TABLE VidaU.Evaluacion (
    idEvaluacion    INT IDENTITY(1,1) CONSTRAINT PK_Evaluacion PRIMARY KEY, -- TIPO IDENTITY PARA QUE GENERE AUTOMATICAMENTE EL IDENTIFICADOR
    idResennia      INT NOT NULL,
    Calificacion    DECIMAL(2,1) NOT NULL,
    Comentario      VARCHAR(500) NULL,
    CONSTRAINT FK_Evaluacion_Resennia FOREIGN KEY (idResennia) -- CONECTA CON LA TABLA RESENNIA
        REFERENCES VidaU.Resennia(idResennia),
    CONSTRAINT CK_Evaluacion_Calificacion CHECK (Calificacion BETWEEN 1 AND 5) -- VERIFICA QUE LA CALIFICACION ESTE ENTRE 1 Y 5
);
GO
