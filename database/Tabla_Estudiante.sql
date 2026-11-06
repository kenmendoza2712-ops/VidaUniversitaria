
CREATE DATABASE VidaUniversitariaDB
GO
 
 -- Estudiante: perfil académico de un Usuario con rol de estudiante.
-- Relación 1:1 con Usuario (ver UQ_Estudiante_Usuario más abajo).
-- FK idUsuario -> Usuario. La columna Carrera guarda el nombre de la carrera como
-- texto informativo; la relación formal con Carrera está en Carrera_Estudiante.
-- Es referenciada por Carrera_Estudiante, Matricula y Resennia.
CREATE TABLE VidaU.Estudiante (
    idEstudiante    INT IDENTITY(1,1) CONSTRAINT PK_Estudiante PRIMARY KEY, -- TIPO IDENTITY PARA QUE GENERE AUTOMATICAMENTE EL IDENTIFICADOR
    idUsuario       INT NOT NULL,
    Carnet          VARCHAR(20) NOT NULL,
    Carrera         VARCHAR(150) NOT NULL,
    AnnoIngreso     INT NOT NULL,
    CONSTRAINT FK_Estudiante_Usuario FOREIGN KEY (idUsuario) -- CONECTA LA TABLA USUARIO
        REFERENCES VidaU.Usuario(idUsuario),
    CONSTRAINT UQ_Estudiante_Usuario UNIQUE (idUsuario), -- relación 1:1 con Usuario
    CONSTRAINT UQ_Estudiante_Carnet UNIQUE (Carnet), -- UNIQUE, CADA ESTUDIANTE POSEE SU PROPIO CARNET, NO SE REPITEN.
    CONSTRAINT CK_Estudiante_AnnoIngreso CHECK (AnnoIngreso >= 2000)-- CHECK VERIFICA QUE EL ANIO DE INGRESO SEA MAYOR O IGUAL AL 2000
);
GO
 