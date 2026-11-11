CREATE DATABASE VidaUniversitariaDB
GO

-- Carrera: programa académico (ej. Ingeniería, Derecho). Ya no depende de una sede:
-- su relación con Sede, Curso y Estudiante es muchos a muchos y se resuelve con
-- tablas puente. Es referenciada por Sede_Carrera, Carrera_Curso y Carrera_Estudiante.
CREATE TABLE VidaU.Carrera (
    idCarrera       INT IDENTITY(1,1) CONSTRAINT PK_Carrera PRIMARY KEY, -- TIPO IDENTITY PARA QUE GENERE AUTOMATICAMENTE EL IDENTIFICADOR
    Nombre          VARCHAR(150) NOT NULL,
    Descripcion     VARCHAR(300) NULL
);
GO
 