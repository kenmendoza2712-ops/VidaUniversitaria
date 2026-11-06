

-- Resennia: reseña que un estudiante deja sobre una leccion específica
-- (profesor + curso + horario juntos, ya que Leccion los combina).
-- FK idLeccion -> Leccion. FK idEstudiante -> Estudiante.
-- UNIQUE (idEstudiante, idLeccion): una sola reseña por estudiante por leccion.
-- NombreCurso y NombreProfesor son copias del momento de la reseña; las llena el
-- procedure a partir de Leccion (no el usuario).
-- La calificación general no se guarda: es el promedio de las calificaciones de
-- sus Evaluacion. Es referenciada por Evaluacion.
CREATE TABLE VidaU.Resennia (
    idResennia          INT IDENTITY(1,1) CONSTRAINT PK_Resennia PRIMARY KEY, -- TIPO IDENTITY PARA QUE GENERE AUTOMATICAMENTE EL IDENTIFICADOR
    idLeccion           INT NOT NULL,
    idEstudiante        INT NOT NULL,
    Estado              VARCHAR(20) NOT NULL CONSTRAINT DF_Resennia_Estado DEFAULT 'EnRevision', -- SI NO SE DEFINE EL ESTADO, QUEDA EN REVISION
    EsAnonima           BIT NOT NULL CONSTRAINT DF_Resennia_EsAnonima DEFAULT 1, -- POR DEFECTO LA RESEÑA ES ANONIMA (1 = SI, 0 = NO)
    NombreCurso         VARCHAR(150) NOT NULL,
    FechaResennia       DATETIME NOT NULL CONSTRAINT DF_Resennia_Fecha DEFAULT GETDATE(), -- SI NO SE DEFINE LA FECHA Y HORA, TOMA LA ACTUAL.
    NombreProfesor      VARCHAR(200) NOT NULL,
    CONSTRAINT FK_Resennia_Leccion FOREIGN KEY (idLeccion) -- CONECTA LA TABLA LECCION
        REFERENCES VidaU.Leccion(idLeccion),
    CONSTRAINT FK_Resennia_Estudiante FOREIGN KEY (idEstudiante) -- CONECTA LA TABLA ESTUDIANTE
        REFERENCES VidaU.Estudiante(idEstudiante),
    CONSTRAINT UQ_Resennia_Estudiante_Leccion UNIQUE (idEstudiante, idLeccion), -- una reseña por estudiante por leccion
    CONSTRAINT CK_Resennia_Estado CHECK (Estado IN ('Visible','Oculta','EnRevision')) -- VERIFICA QUE EL ESTADO SEA VISIBLE, OCULTA O EN REVISION
);
GO