
CREATE DATABASE VidaUniversitariaDB
GO
 
USE VidaUniversitariaDB
GO
 
-- Esquema propio del proyecto (nunca usar dbo directamente)
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'VidaU')
BEGIN
    EXEC('CREATE SCHEMA VidaU');
END
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
 
-- Plan: catálogo de planes de suscripción que una universidad puede contratar
-- (ej. Plan Básico, Plan Institucional). No depende de ninguna otra tabla;
-- es referenciada por Suscripcion.
-- PLAN ES PALABRA RESERVADA EN SQL SERVER, POR ESO SE ESCRIBE ENTRE CORCHETES [Plan]
CREATE TABLE VidaU.[Plan] (
    idPlan          INT IDENTITY(1,1) CONSTRAINT PK_Plan PRIMARY KEY, -- TIPO IDENTITY PARA QUE GENERE AUTOMATICAMENTE EL IDENTIFICADOR
    Nombre          VARCHAR(100) NOT NULL,
    Descripcion     VARCHAR(300) NULL,
    Monto           DECIMAL(10,2) NOT NULL,
    CONSTRAINT CK_Plan_Monto CHECK (Monto >= 0)  -- CHECK VERIFICA QUE EL MONTO SEA MAYOR O IGUAL A 0
);
GO
 
-- Universidad: institución que usa la plataforma. Es la entidad raíz de la
-- que dependen sedes, profesores y suscripciones.
-- Es referenciada por Sede, Suscripcion y Universidad_Profesor.
CREATE TABLE VidaU.Universidad (
    idUniversidad   INT IDENTITY(1,1) CONSTRAINT PK_Universidad PRIMARY KEY, -- TIPO IDENTITY PARA QUE GENERE AUTOMATICAMENTE EL IDENTIFICADOR
    Nombre          VARCHAR(150) NOT NULL,
    Correo          VARCHAR(150) NOT NULL,
    Estado          VARCHAR(20)  NOT NULL CONSTRAINT DF_Universidad_Estado DEFAULT 'Activa', -- VALOR AUTOMATICO "ACTIVA"
    Telefono        VARCHAR(20)  NULL,
    CONSTRAINT UQ_Universidad_Correo UNIQUE (Correo), -- UNIQUE NO PERMITE VALORES REPETIDOS, EJEMPLO DOS UNIVERSIDADES CON EL MISMO CORREO
    CONSTRAINT CK_Universidad_Estado CHECK (Estado IN ('Activa','Inactiva')) -- CHECK VALIDA QUE ESTE ACTIVA O INACTIVA
);
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
 
-- Profesor: docente que imparte lecciones. Se relaciona con Universidad mediante la
-- tabla puente Universidad_Profesor (un profesor puede dar clases en varias universidades).
-- Es referenciada por Universidad_Profesor y Leccion.
CREATE TABLE VidaU.Profesor (
    idProfesor      INT IDENTITY(1,1) CONSTRAINT PK_Profesor PRIMARY KEY, -- TIPO IDENTITY PARA QUE GENERE AUTOMATICAMENTE EL IDENTIFICADOR
    Nombre          VARCHAR(100) NOT NULL,
    Apellido        VARCHAR(100) NOT NULL,
    Correo          VARCHAR(150) NOT NULL,
    CONSTRAINT UQ_Profesor_Correo UNIQUE (Correo) -- UNIQUE NO PERMITE VALORES REPETIDOS, EJEMPLO DOS PROFESORES CON EL MISMO CORREO
);
GO
 
/* 
   TABLAS DE PRIMER NIVEL (dependen de las anteriores)
 */
 
-- Sede: campus o sucursal física de una universidad. Una universidad puede
-- tener varias sedes. FK idUniversidad -> Universidad.
-- Se relaciona con Carrera mediante la tabla puente Sede_Carrera.
CREATE TABLE VidaU.Sede (
    idSede          INT IDENTITY(1,1) CONSTRAINT PK_Sede PRIMARY KEY, -- TIPO IDENTITY PARA QUE GENERE AUTOMATICAMENTE EL IDENTIFICADOR
    idUniversidad   INT NOT NULL,
    Nombre          VARCHAR(150) NOT NULL,
    Estado          VARCHAR(20)  NOT NULL CONSTRAINT DF_Sede_Estado DEFAULT 'Activa', -- SI NO SE INGRESA EL ESTADO, LO DEFINE COMO ACTIVA.
    Direccion       VARCHAR(250) NULL,
    CONSTRAINT FK_Sede_Universidad FOREIGN KEY (idUniversidad) -- CONECTA LA TABLA UNIVERSIDAD
        REFERENCES VidaU.Universidad(idUniversidad),
    CONSTRAINT CK_Sede_Estado CHECK (Estado IN ('Activa','Inactiva')) -- CHECK VALIDA QUE ESTE ACTIVA O INACTIVA
);
GO
 
-- Suscripcion: contrato activo entre una universidad y un plan de la
-- plataforma. Permite llevar control de pagos/vigencia.
-- FK idUniversidad -> Universidad. FK idPlan -> Plan.
CREATE TABLE VidaU.Suscripcion (
    idSuscripcion   INT IDENTITY(1,1) CONSTRAINT PK_Suscripcion PRIMARY KEY,  -- TIPO IDENTITY PARA QUE GENERE AUTOMATICAMENTE EL IDENTIFICADOR
    idUniversidad   INT NOT NULL,
    idPlan          INT NOT NULL,
    Estado          VARCHAR(20) NOT NULL CONSTRAINT DF_Suscripcion_Estado DEFAULT 'Activa', -- SI NO SE INGRESA EL ESTADO, LO DEFINE COMO ACTIVA.
    FechaInicio     DATE NOT NULL,
    FechaFin        DATE NULL,
    CONSTRAINT FK_Suscripcion_Universidad FOREIGN KEY (idUniversidad) -- CONECTA LA TABLA UNIVERSIDAD
        REFERENCES VidaU.Universidad(idUniversidad),
    CONSTRAINT FK_Suscripcion_Plan FOREIGN KEY (idPlan) -- CONECTA LA TABLA PLAN
        REFERENCES VidaU.[Plan](idPlan),
    CONSTRAINT CK_Suscripcion_Estado CHECK (Estado IN ('Activa','Inactiva','Vencida')), -- CHECK, VERIFICA QUE EL ESTADO SEA ACTIVA, INACTIVA O VENCIDA.
    CONSTRAINT CK_Suscripcion_Fechas CHECK (FechaFin IS NULL OR FechaFin >= FechaInicio) -- CHECK, SI LA FECHA DE FINALIZACION ES NULA O MAYOR O IGUAL A LA FECHA DE INICIO.
);
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
 
-- Leccion: combinación concreta de un curso + un profesor + un horario.
-- Es lo que un estudiante reseña (antes se llamaba Imparticion).
-- FK idCurso -> Curso. FK idProfesor -> Profesor.
-- Es referenciada por Resennia.
CREATE TABLE VidaU.Leccion (
    idLeccion       INT IDENTITY(1,1) CONSTRAINT PK_Leccion PRIMARY KEY, -- TIPO IDENTITY PARA QUE GENERE AUTOMATICAMENTE EL IDENTIFICADOR
    idCurso         INT NOT NULL,
    idProfesor      INT NOT NULL,
    Horario         VARCHAR(100) NOT NULL,
    Aula            VARCHAR(50)  NULL,
    Cupo            INT NOT NULL,
    CONSTRAINT FK_Leccion_Curso FOREIGN KEY (idCurso) -- CONECTA CON LA TABLA CURSO
        REFERENCES VidaU.Curso(idCurso),
    CONSTRAINT FK_Leccion_Profesor FOREIGN KEY (idProfesor) -- CONECTA CON LA TABLA PROFESOR
        REFERENCES VidaU.Profesor(idProfesor),
    CONSTRAINT CK_Leccion_Cupo CHECK (Cupo > 0) -- El cupo total de la leccion no puede ser cero ni negativo 
);
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
 
-- Sede_Carrera: una sede ofrece varias carreras y una carrera se ofrece
-- en varias sedes.
CREATE TABLE VidaU.Sede_Carrera (
    idSede          INT NOT NULL,
    idCarrera       INT NOT NULL,
    CONSTRAINT PK_Sede_Carrera PRIMARY KEY (idSede, idCarrera), -- PK COMPUESTA: LA MISMA PAREJA NO SE PUEDE REPETIR
    CONSTRAINT FK_SedeCarr_Sede FOREIGN KEY (idSede) -- CONECTA LA TABLA SEDE
        REFERENCES VidaU.Sede(idSede),
    CONSTRAINT FK_SedeCarr_Carrera FOREIGN KEY (idCarrera) -- CONECTA LA TABLA CARRERA
        REFERENCES VidaU.Carrera(idCarrera)
);
GO
 
-- Carrera_Curso: una carrera contiene varios cursos y un curso puede
-- pertenecer a varias carreras.
CREATE TABLE VidaU.Carrera_Curso (
    idCarrera       INT NOT NULL,
    idCurso         INT NOT NULL,
    CONSTRAINT PK_Carrera_Curso PRIMARY KEY (idCarrera, idCurso), -- PK COMPUESTA: LA MISMA PAREJA NO SE PUEDE REPETIR
    CONSTRAINT FK_CarrCurso_Carrera FOREIGN KEY (idCarrera) -- CONECTA LA TABLA CARRERA
        REFERENCES VidaU.Carrera(idCarrera),
    CONSTRAINT FK_CarrCurso_Curso FOREIGN KEY (idCurso) -- CONECTA LA TABLA CURSO
        REFERENCES VidaU.Curso(idCurso)
);
GO
 
-- Carrera_Estudiante: un estudiante puede cursar varias carreras y una
-- carrera tiene muchos estudiantes.
CREATE TABLE VidaU.Carrera_Estudiante (
    idCarrera       INT NOT NULL,
    idEstudiante    INT NOT NULL,
    CONSTRAINT PK_Carrera_Estudiante PRIMARY KEY (idCarrera, idEstudiante), -- PK COMPUESTA: LA MISMA PAREJA NO SE PUEDE REPETIR
    CONSTRAINT FK_CarrEst_Carrera FOREIGN KEY (idCarrera) -- CONECTA LA TABLA CARRERA
        REFERENCES VidaU.Carrera(idCarrera),
    CONSTRAINT FK_CarrEst_Estudiante FOREIGN KEY (idEstudiante) -- CONECTA LA TABLA ESTUDIANTE
        REFERENCES VidaU.Estudiante(idEstudiante)
);
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