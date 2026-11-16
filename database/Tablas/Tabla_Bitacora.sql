
CREATE DATABASE VidaUniversitariaDB
GO
 

/* 
   TABLAS DE SEGUNDO NIVEL
*/
 
-- Bitacora: registro de auditoría. Guarda qué acción hizo cada usuario y
-- cuándo, para trazabilidad del sistema. FK idUsuario -> Usuario.
CREATE TABLE VidaU.Bitacora (
    idBitacora      INT IDENTITY(1,1) CONSTRAINT PK_Bitacora PRIMARY KEY, -- TIPO IDENTITY PARA QUE GENERE AUTOMATICAMENTE EL IDENTIFICADOR
    idUsuario       INT NOT NULL,
    Accion          VARCHAR(100) NOT NULL,
    TablaAfectada   VARCHAR(100) NOT NULL,
    FechaHora       DATETIME NOT NULL CONSTRAINT DF_Bitacora_FechaHora DEFAULT GETDATE(), -- SI NO SE DEFINE LA FECHA Y HORA, TOMA LA ACTUAL.
    Descripcion     VARCHAR(500) NULL,
    CONSTRAINT FK_Bitacora_Usuario FOREIGN KEY (idUsuario) -- CONECTA LA TABLA USUARIO
        REFERENCES VidaU.Usuario(idUsuario)
);
GO