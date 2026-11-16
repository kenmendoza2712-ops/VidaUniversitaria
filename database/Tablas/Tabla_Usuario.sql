CREATE DATABASE VidaUniversitariaDB
GO
 

-- Usuario: cuenta de acceso al sistema (login). Cualquier persona que entra
-- a la plataforma tiene un registro aquí. FK idRol -> Rol.
-- Es referenciada por Estudiante y Bitacora.
CREATE TABLE VidaU.Usuario (
    idUsuario       INT IDENTITY(1,1) CONSTRAINT PK_Usuario PRIMARY KEY, -- TIPO IDENTITY PARA QUE GENERE AUTOMATICAMENTE EL IDENTIFICADOR
    idRol           INT NOT NULL,
    Nombre          VARCHAR(100) NOT NULL,
    Apellidos       VARCHAR(100) NOT NULL,
    Correo          VARCHAR(150) NOT NULL,
    Contrasena      VARBINARY(256) NOT NULL, -- se guarda con HASHBYTES, nunca texto plano
    CONSTRAINT FK_Usuario_Rol FOREIGN KEY (idRol) -- CONECTA LA TABLA ROL
        REFERENCES VidaU.Rol(idRol),
    CONSTRAINT UQ_Usuario_Correo UNIQUE (Correo) -- UNIQUE, NO SE REPITEN CORREOS.
);
GO
 