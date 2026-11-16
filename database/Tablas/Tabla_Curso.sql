CREATE DATABASE VidaUniversitariaDB
GO
 
-- Curso: materia (ej. Bases de Datos II). Se relaciona con Carrera mediante la
-- tabla puente Carrera_Curso. Es referenciada por Carrera_Curso y Leccion.
CREATE TABLE VidaU.Curso (
    idCurso         INT IDENTITY(1,1) CONSTRAINT PK_Curso PRIMARY KEY, -- TIPO IDENTITY PARA QUE GENERE AUTOMATICAMENTE EL IDENTIFICADOR
    Nombre          VARCHAR(150) NOT NULL,
    Descripcion     VARCHAR(300) NULL,
    Creditos        INT NOT NULL,
    CONSTRAINT CK_Curso_Creditos CHECK (Creditos > 0) -- CHECK VERIFICA QUE LOS CREDITOS SEAN MAYORES A 0
);
GO