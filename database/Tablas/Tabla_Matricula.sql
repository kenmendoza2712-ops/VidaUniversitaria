CREATE DATABASE VidaUniversitariaDB
GO

/*
   TABLAS DE TERCER NIVEL
*/
 
-- Matricula: registro de la matrícula de un estudiante (fecha y estado).
-- FK idEstudiante -> Estudiante. Según el modelo, Matricula no se relaciona con Leccion.
CREATE TABLE VidaU.Matricula (
    idMatricula     INT IDENTITY(1,1) CONSTRAINT PK_Matricula PRIMARY KEY, -- TIPO IDENTITY PARA QUE GENERE AUTOMATICAMENTE EL IDENTIFICADOR
    idEstudiante    INT NOT NULL,
    FechaMatricula  DATE NOT NULL CONSTRAINT DF_Matricula_Fecha DEFAULT CAST(GETDATE() AS DATE), -- GETDATE() devuelve la fecha y hora actual del servidor. Pero como FechaMatricula es tipo DATE (sin hora), se usa CAST(GETDATE ()AS DATE) para quedarte solo con la parte de fecha. Si no llenamos este campo al insertar, se llena automáticamente con el día de hoy.
    Estado          VARCHAR(20) NOT NULL CONSTRAINT DF_Matricula_Estado DEFAULT 'Matriculado', -- SI NO SE ESPECIFICA EL ESTADO, ASUME QUE ESTA MATRICULADO
    CONSTRAINT FK_Matricula_Estudiante FOREIGN KEY (idEstudiante) -- CONECTA CON LA TABLA ESTUDIANTE
        REFERENCES VidaU.Estudiante(idEstudiante),
    CONSTRAINT CK_Matricula_Estado CHECK (Estado IN ('Matriculado','Retirado','Finalizado')) -- check, verifica que el estado sea matriculado, retirado, finalizado
);
GO