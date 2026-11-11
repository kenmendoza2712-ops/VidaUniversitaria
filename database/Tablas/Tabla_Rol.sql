USE VidaUniversitariaDB
GO

/* 
   TABLAS SIN DEPENDENCIAS (catálogos / raíces)
*/
 
-- Rol: catálogo de roles del sistema (ej. Estudiante, Administrador, Coordinador).
-- Define qué tipo de usuario es cada cuenta. No depende de ninguna otra tabla;
-- es referenciada por Usuario.
CREATE TABLE VidaU.Rol (
    idRol           INT IDENTITY(1,1) CONSTRAINT PK_Rol PRIMARY KEY, -- TIPO IDENTITY PARA QUE GENERE AUTOMATICAMENTE EL IDENTIFICADOR
    Nombre          VARCHAR(50)  NOT NULL,
    Descripcion     VARCHAR(200) NULL,
    CONSTRAINT UQ_Rol_Nombre UNIQUE (Nombre) -- UNIQUE IMPIDE QUE EXISTAN DOS ROLES CON EL MISMO NOMBRE 
);
GO