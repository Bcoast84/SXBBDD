
-- BASES DE DATOS CONTENIDAS
-- Activamos opciones avanzadas
	EXEC sp_configure 'show advanced options' 1
	GO
	
-- Activamos BD contenidas
	EXEC sp_configure 'contained database authentication', 1
	GO


-- Creamos la base de datos
	DROP DATABASE IF EXISTS Contenida
	GO
	CREATE DATABASE Contenida
	CONTAINMENT=PARTIAL
	GO

-- Activamos opciones avanzadas
EXEC sp_configure 'show advanced options' 1
GO
	
-- Activamos BD contenidas
EXEC sp_configure 'contained database authentication', 1
GO
-- Modificamos la base de datos para convertirla en contenida
ALTER DATABASE [NombreDeLaBaseDeDatos]
SET CONTAINMENT = PARTIAL;
GO






---------------------------------------------------------------------------------------------
-- BLOB(Binary Large Object)

-- NTFS (Carpetas del sistema)

--Activar el filestream access
EXEC sp_configure 'show advanced options',1;
GO
EXEC sp_configure 'filestream_access_level', 2; 
RECONFIGURE;
GO

-- 0 = Deshabilitado. (valor por defecto).
-- 1 = Habilitado solo para acceso de T-SQL.
-- 2 = Habilitado para T-SQL y acceso local al sistema de ficheros.
-- 3 = Habilitado para T-SQL, acceso local y remoto al sistema de ficheros.


-- Crear carpeta para almacenar los archivos
EXECUTE sp_configure 'show advanced options',1;
GO
EXECUTE sp_configure 'xp_cmdshell', 1;
GO
EXECUTE autoescuelap xp_cmdshell 'mkdir c:\Fotos_profesores\'
GO
EXECUTE sp_configure 'show advanced options',0;
GO

-- Añadimos la columna para guardar los archivos:
ALTER TABLE profesor
ADD fotografía VARBINARY(MAX),
    extension NVARCHAR(10);
GO;

-- Insertamos datos
UPDATE profesor
SET fotografía = (SELECT BULKCOLUMN
FROM OPENROWSET(BULK N'C:\Fotos_profesores\profesor1.JPG', SINGLE_BLOB) AS archivo),
extension = 'JPG'
WHERE profesor_DNI_profe = '10987654R';
GO

UPDATE profesor
SET fotografía = (SELECT BULKCOLUMN 
                  FROM OPENROWSET(BULK N'C:\Fotos_profesores\profesor2.JPG', SINGLE_BLOB) AS archivo),
    extension = 'JPG'
WHERE profesor_DNI_profe = '09876543Q';
GO

UPDATE profesor
SET fotografía = (SELECT BULKCOLUMN 
                  FROM OPENROWSET(BULK N'C:\Fotos_profesores\profesor3.JPG', SINGLE_BLOB) AS archivo),
    extension = 'JPG'
WHERE profesor_DNI_profe = '32109876T';
GO

-- Comprobamos las inserciones
SELECT profesor_N_profe, profesor_Apel1_profe, profesor_Apel2_profe, fotografía, extension FROM profesor;
GO

------------------------------------------------------------------------------------------------------
-- FILESTREAM
-- activamos FILESTREAM (si no lo hemos hecho en configuration manager)
EXEC sp_configure filestream_access_level, 2
RECONFIGURE
GO
-- Si no funcionase, acordarse de activarlo en Configuration Manager y reiniciar el servicio de SQLserver

-- Creamos un FILEGROUP que contenga Filestream
ALTER DATABASE autoescuelaP
ADD FILEGROUP fg_imagenes CONTAINS FILESTREAM
GO

-- Asociamos un fichero físico con el FILEGROUP
ALTER DATABASE AutoescuelaP
	ADD FILE (NAME = 'Imagenes_FS',
	FILENAME = 'C:\DATA\Imagenes_FS')
	TO FILEGROUP fg_imagenes
GO

SELECT * FROM sys.filegroups
ORDER BY data_space_id DESC;
GO

-- Creamos la tabla
-- IMPORTANTE añadir ID2 y acordarse de definir el campo del archivo como FILESTREAM
CREATE TABLE [dbo].[profesor_FS](
	[ID2] UNIQUEIDENTIFIER ROWGUIDCOL NOT NULL UNIQUE,
	[profesor_DNI_profe] [varchar](9) NOT NULL PRIMARY KEY,
	[profesor_N_profe] [nvarchar](12) NULL,
	[profesor_Apel1_profe] [nvarchar](12) NULL,
	[profesor_Apel2_profe] [nvarchar](12) NULL,
	[profesor_Email_profe] [nvarchar](40) NULL,
	[profesor_Telf_profe] [nvarchar](16) NULL,
	[localidad_cod_localidad] [int] NOT NULL,
	[fotografía] [varbinary](max) FILESTREAM,
	[extension] [nvarchar](10) NULL)
GO


-- Añadir registros
INSERT INTO profesor_FS (ID2,profesor_DNI_profe,profesor_N_profe,profesor_Apel1_profe,localidad_cod_localidad,fotografía,extension)
	SELECT NEWID(),'32840700N','Borja','Costa',10, BULKCOLUMN,'JPG'
	FROM OPENROWSET(BULK 'C:\Fotos_profesores\Profesor1.JPG', SINGLE_BLOB) AS FOTO
GO



INSERT INTO profesor_FS (ID2,profesor_DNI_profe,profesor_N_profe,profesor_Apel1_profe,localidad_cod_localidad,fotografía,extension)
	SELECT NEWID(),'13855702H','Jose','Crego',10, BULKCOLUMN,'JPG'
	FROM OPENROWSET(BULK 'C:\Fotos_profesores\Profesor2.JPG', SINGLE_BLOB) AS FOTO
GO

SELECT * FROM profesor_FS;
GO


-- Otro ejemplo FILESTREAM

-- Creamos el filegroup
ALTER DATABASE [autoescuelap]
ADD FILEGROUP [Fotoprofes] CONTAINS FILESTREAM;
GO

-- añadimos el fichero donde vamos a almacenar el filegroup (las imagenes)
ALTER DATABASE [autoescuelap]
	ADD FILE (NAME='FOTOGRAFIAS',
	FILENAME = 'C:\FOTOGRAFIAS')
	TO FILEGROUP [Fotoprofes]
GO

-- Creamos la tabla
CREATE TABLE Orla
(ID INT IDENTITY,
 ID2 UNIQUEIDENTIFIER ROWGUIDCOL NOT NULL UNIQUE,
 nombre varchar(255),
 fotografía VARBINARY(MAX) FILESTREAM,
 extension CHAR(5)
 )
 GO

INSERT INTO Orla (ID2,nombre,fotografía,extension)
	SELECT NEWID(), 'Borja', BULKCOLUMN, 'JPG'
	FROM OPENROWSET(BULK 'c:\FOTOGRAFIAS', SINGLE_BLOB) AS fotografia
GO

 INSERT INTO Orla (ID2,nombre,fotografía,extension)
	SELECT NEWID(), 'Marta', BULKCOLUMN, 'JPG'
	FROM OPENROWSET(BULK 'c:\Fotos_profesores\profesor2.jpg', SINGLE_BLOB) AS fotografia
GO

 INSERT INTO Orla (ID2,nombre,fotografía,extension)
	SELECT NEWID(), 'Juanjo', BULKCOLUMN, 'JPG'
	FROM OPENROWSET(BULK 'c:\Fotos_profesores\profesor3.jpg', SINGLE_BLOB) AS fotografia
GO

--Comprobamos
SELECT * FROM Orla;
GO



----------------------------------------------------------------------------------------------------------------
-- FILETABLES

-- Recomendado hacerlo desde master
USE master
GO


--Activamos filestream
ALTER DATABASE [autoescuelap]
SET FILESTREAM (DIRECTORY_NAME = 'FotografiaStore')
WITH ROLLBACK IMMEDIATE
GO

ALTER DATABASE [autoescuelap]
	SET FILESTREAM(NON_TRANSACTED_ACCESS = FULL,
	DIRECTORY_NAME = 'FOTOGRAFIA')
	WITH ROLLBACK IMMEDIATE
GO

--Creamos tabla FILETABLE
CREATE TABLE FotografiaStore AS FILETABLE
WITH
(
	FileTable_Directory = 'FotografiaStore',
	FileTable_Collate_Filename = database_default,
	FILETABLE_STREAMID_UNIQUE_CONSTRAINT_NAME=UQ_stream_id
);
GO
-- Copiamos las fotos a insertar en la carpeta creada

-- Comprobamos
SELECT * FROM FotografiaStore;
GO




-------------------------------------------------------------------------------------------------------------------
-- PARTICIONES

CREATE DATABASE [AutoescuelaP] 
	ON PRIMARY ( NAME = 'AutoescuelaP', 
		FILENAME = 'C:\Data\AutoescuelaP_Fijo.mdf' , 
		SIZE = 15360KB , MAXSIZE = UNLIMITED, FILEGROWTH = 0) 
	LOG ON ( NAME = 'AutoescuelaP_log', 
		FILENAME = 'C:\Data\AutoescuelaP_log.ldf' , 
		SIZE = 10176KB , MAXSIZE = 2048GB , FILEGROWTH = 10%) 
GO

use autoescuelaP;
GO

EXECUTE sp_configure 'xp_cmdshell', 1;
GO
RECONFIGURE;
GO
xp_cmdshell 'mkdir C:\DATA\'
GO

-- 1.- CREO FILEGROUPS
-- Solo tiene sentido en bases de datos grandes y cuando se almacenan en diferentes discos

ALTER DATABASE [autoescuelaP] ADD FILEGROUP [Antiguos] 
GO 

ALTER DATABASE [autoescuelaP] ADD FILEGROUP [Altas_2023] 
GO 

ALTER DATABASE [autoescuelaP] ADD FILEGROUP [Altas_2024] 
GO 

ALTER DATABASE [autoescuelaP] ADD FILEGROUP [Altas_2025]
GO



select * from sys.filegroups

GO

-- 2.- CREO LOS ARCHIVOS Y VINCULO LOS FILEGROUPS
-- Se crean archivos para añadir cada filegroup a un archivo



ALTER DATABASE [autoescuelaP] ADD FILE ( NAME = 'Antiguos', FILENAME = 'c:\DATA\Antiguos.ndf', SIZE = 5MB, MAXSIZE = 100MB, FILEGROWTH = 2MB ) TO FILEGROUP [Antiguos] 
GO

ALTER DATABASE [autoescuelaP] ADD FILE ( NAME = 'Altas_2023', FILENAME = 'c:\DATA\Altas_2023.ndf', SIZE = 5MB, MAXSIZE = 100MB, FILEGROWTH = 2MB ) TO FILEGROUP [Altas_2023] 
GO

ALTER DATABASE [autoescuelaP] ADD FILE ( NAME = 'Altas_2024', FILENAME = 'c:\DATA\Altas_2024.ndf', SIZE = 5MB, MAXSIZE = 100MB, FILEGROWTH = 2MB ) TO FILEGROUP [Altas_2024] 
GO

ALTER DATABASE [autoescuelaP] ADD FILE ( NAME = 'Altas_2025', FILENAME = 'c:\DATA\Altas_2025.ndf', SIZE = 5MB, MAXSIZE = 100MB, FILEGROWTH = 2MB ) TO FILEGROUP [Altas_2025] 
GO

select file_id, name, physical_name
from sys.database_files
GO

-- 3.- CREO FUNCION PARTICION
-- Lo que hace es crear una función que particiones los datos, en este caso según fecha
-- Los rangos deben estar ordenados sino nos saltará un warning

DROP PARTITION FUNCTION FN_altas_fecha;
GO

CREATE PARTITION FUNCTION FN_altas_fecha (datetime) 
AS RANGE RIGHT 
	FOR VALUES ('2023-01-01','2024-01-01','2025-01-01')

GO

-- 4.- CREO EL ESQUEMA DE PARTICIÓN
-- Nos mapeará los registros según las particiones

CREATE PARTITION SCHEME altas_fecha 
AS PARTITION FN_altas_fecha 
	TO (Antiguos,Altas_2023,Altas_2024,Altas_2025) 
GO

-- 5.- CREO TABLA
DROP TABLE IF EXISTS Alta_Coleg
GO

CREATE TABLE Altas_matricula
	( id_alta int identity (1,1), 
	nombre varchar(20), 
	apellido varchar (20), 
	fecha_alta datetime ) 
	ON altas_fecha 
		(fecha_alta) 
GO


-- Pedimos a la IA que nos genere registros de ejemplo para rellenar la tabla
INSERT INTO Altas_matricula (nombre, apellido, fecha_alta) VALUES ('Carlos', 'García', '2019-03-10');
INSERT INTO Altas_matricula (nombre, apellido, fecha_alta) VALUES ('María', 'Martínez', '2021-05-12');
INSERT INTO Altas_matricula (nombre, apellido, fecha_alta) VALUES ('José', 'López', '2022-07-24');
INSERT INTO Altas_matricula (nombre, apellido, fecha_alta) VALUES ('Laura', 'González', '2020-11-19');
INSERT INTO Altas_matricula (nombre, apellido, fecha_alta) VALUES ('Antonio', 'Rodríguez', '2023-02-03');
INSERT INTO Altas_matricula (nombre, apellido, fecha_alta) VALUES ('Ana', 'Pérez', '2024-01-15');
INSERT INTO Altas_matricula (nombre, apellido, fecha_alta) VALUES ('David', 'Sánchez', '2023-08-05');
INSERT INTO Altas_matricula (nombre, apellido, fecha_alta) VALUES ('Carmen', 'Hernández', '2021-09-18');
INSERT INTO Altas_matricula (nombre, apellido, fecha_alta) VALUES ('Francisco', 'Díaz', '2022-04-07');
INSERT INTO Altas_matricula (nombre, apellido, fecha_alta) VALUES ('Luis', 'Jiménez', '2019-12-20');
INSERT INTO Altas_matricula (nombre, apellido, fecha_alta) VALUES ('Carlos', 'García', '2020-06-02');
INSERT INTO Altas_matricula (nombre, apellido, fecha_alta) VALUES ('María', 'Martínez', '2024-04-15');
INSERT INTO Altas_matricula (nombre, apellido, fecha_alta) VALUES ('José', 'López', '2021-11-11');
INSERT INTO Altas_matricula (nombre, apellido, fecha_alta) VALUES ('Laura', 'González', '2023-01-25');
INSERT INTO Altas_matricula (nombre, apellido, fecha_alta) VALUES ('Antonio', 'Rodríguez', '2022-05-30');
INSERT INTO Altas_matricula (nombre, apellido, fecha_alta) VALUES ('Ana', 'Pérez', '2024-03-22');
INSERT INTO Altas_matricula (nombre, apellido, fecha_alta) VALUES ('David', 'Sánchez', '2023-10-14');
INSERT INTO Altas_matricula (nombre, apellido, fecha_alta) VALUES ('Carmen', 'Hernández', '2021-02-19');
INSERT INTO Altas_matricula (nombre, apellido, fecha_alta) VALUES ('Francisco', 'Díaz', '2022-01-09');
INSERT INTO Altas_matricula (nombre, apellido, fecha_alta) VALUES ('Luis', 'Jiménez', '2020-07-10');
INSERT INTO Altas_matricula (nombre, apellido, fecha_alta) VALUES ('Carlos', 'García', '2024-10-11');
INSERT INTO Altas_matricula (nombre, apellido, fecha_alta) VALUES ('María', 'Martínez', '2019-11-04');
INSERT INTO Altas_matricula (nombre, apellido, fecha_alta) VALUES ('José', 'López', '2020-01-20');
INSERT INTO Altas_matricula (nombre, apellido, fecha_alta) VALUES ('Laura', 'González', '2021-04-08');
INSERT INTO Altas_matricula (nombre, apellido, fecha_alta) VALUES ('Antonio', 'Rodríguez', '2022-08-13');
INSERT INTO Altas_matricula (nombre, apellido, fecha_alta) VALUES ('Ana', 'Pérez', '2023-12-17');
INSERT INTO Altas_matricula (nombre, apellido, fecha_alta) VALUES ('David', 'Sánchez', '2024-01-28');
INSERT INTO Altas_matricula (nombre, apellido, fecha_alta) VALUES ('Carmen', 'Hernández', '2022-10-21');
INSERT INTO Altas_matricula (nombre, apellido, fecha_alta) VALUES ('Francisco', 'Díaz', '2021-03-04');
INSERT INTO Altas_matricula (nombre, apellido, fecha_alta) VALUES ('Luis', 'Jiménez', '2023-02-11');
INSERT INTO Altas_matricula (nombre, apellido, fecha_alta) VALUES ('Carlos', 'García', '2021-06-14');
INSERT INTO Altas_matricula (nombre, apellido, fecha_alta) VALUES ('María', 'Martínez', '2022-02-01');
INSERT INTO Altas_matricula (nombre, apellido, fecha_alta) VALUES ('José', 'López', '2023-06-09');
INSERT INTO Altas_matricula (nombre, apellido, fecha_alta) VALUES ('Laura', 'González', '2020-10-15');
INSERT INTO Altas_matricula (nombre, apellido, fecha_alta) VALUES ('Antonio', 'Rodríguez', '2018-09-21');
INSERT INTO Altas_matricula (nombre, apellido, fecha_alta) VALUES ('Ana', 'Pérez', '2021-07-23');
INSERT INTO Altas_matricula (nombre, apellido, fecha_alta) VALUES ('David', 'Sánchez', '2024-02-17');
INSERT INTO Altas_matricula (nombre, apellido, fecha_alta) VALUES ('Carmen', 'Hernández', '2023-11-14');
INSERT INTO Altas_matricula (nombre, apellido, fecha_alta) VALUES ('Francisco', 'Díaz', '2024-09-28');
INSERT INTO Altas_matricula (nombre, apellido, fecha_alta) VALUES ('Luis', 'Jiménez', '2020-12-05');
GO
INSERT INTO Altas_matricula (nombre, apellido, fecha_alta)
VALUES
('Carlos', 'Martínez', '2025-02-15'),
('Ana', 'López', '2025-03-21'),
('José', 'González', '2025-04-09'),
('Laura', 'Pérez', '2025-05-02'),
('Miguel', 'Sánchez', '2025-06-18'),
('Lucía', 'Ramírez', '2025-07-11'),
('Pablo', 'Torres', '2025-08-24'),
('María', 'Hernández', '2025-09-07'),
('David', 'García', '2025-10-03'),
('Sofía', 'Martín', '2025-11-16'),
('Pedro', 'Álvarez', '2025-12-29'),
('Raquel', 'Rodríguez', '2025-01-11'),
('Fernando', 'Díaz', '2025-02-02'),
('Isabel', 'Jiménez', '2025-03-10'),
('Javier', 'Molina', '2025-04-04'),
('Elena', 'Vázquez', '2025-05-30'),
('Francisco', 'Castro', '2025-06-27'),
('Marcos', 'Ruiz', '2025-07-18'),
('Carmen', 'Moreno', '2025-08-13'),
('Juan', 'Gil', '2025-09-02');
GO

-- Comprobaciones

SELECT p.partition_number AS Numero_Particion,
       p.rows AS Registros
FROM sys.partitions p
JOIN sys.indexes i 
    ON p.object_id = i.object_id
WHERE i.object_id = OBJECT_ID('Altas_matricula') 
ORDER BY p.partition_number;
GO

SELECT *,$Partition.FN_altas_fecha(fecha_alta) AS Partition
FROM Altas_matricula
GO

-- SPLIT (Dividir particiones)
-- Como no hemos dejado groupfiles libres, ahora debemos crear un groupfile, adjudicarle un archivo y modificar el esquema de la partición

ALTER DATABASE [autoescuelaP] ADD FILEGROUP [Altas_2022] 
GO 

ALTER DATABASE [autoescuelaP] ADD FILE ( NAME = 'Altas_2022', FILENAME = 'c:\DATA\Altas_2022.ndf', SIZE = 5MB, MAXSIZE = 100MB, FILEGROWTH = 2MB ) TO FILEGROUP [Altas_2022] 
GO

ALTER PARTITION SCHEME altas_fecha 
NEXT USED Altas_2022;


ALTER PARTITION FUNCTION FN_altas_fecha() 
	SPLIT RANGE ('2022-01-01'); 
GO

SELECT *,$Partition.FN_altas_fecha(fecha_alta) AS Partition
FROM Altas_matricula
GO


-- MERGE (Fusionar particiones)

ALTER PARTITION FUNCTION FN_Altas_Fecha ()
 MERGE RANGE ('2022-01-01'); 
 GO

SELECT *,$Partition.FN_altas_fecha(fecha_alta) AS Partition
FROM Altas_matricula
GO

-- SWITCH (Intercambiar)
-- Lo que vamos a hacer es intercambiar una de las particiones a otra tabla
-- En este caso intercambiaremos las altas antiguas para que queden solo del 2023 en adelante

DROP TABLE IF EXISTS Archivo_antiguos 
GO

CREATE TABLE Archivo_antiguos 
( id_alta int identity (1,1), 
nombre varchar(20), 
apellido varchar (20), 
fecha_alta datetime ) 
ON Antiguos
GO

ALTER TABLE Altas_matricula 
	SWITCH Partition 1 to Archivo_antiguos
GO

select * from Altas_matricula
GO

-- TRUNCATE (Eliminar)
-- Vamos a probar a borrar la partición 4 que es la que tiene las altas del último año.

TRUNCATE TABLE Altas_matricula
	WITH (PARTITIONS (4));
GO


select * from Altas_matricula
GO

SELECT *,$Partition.FN_altas_fecha(fecha_alta) AS Partition
FROM Altas_matricula
GO

DROP TABLE Altas_matricula;
GO

-- Siempre hay que incluir el discriminando de la partición dentro de la PK de la tabla particionada
CREATE TABLE Altas_matricula
(
    id_alta INT IDENTITY (1,1), 
    nombre VARCHAR(20), 
    apellido VARCHAR(20), 
    fecha_alta DATETIME, 
    CONSTRAINT PK_Altas_matricula PRIMARY KEY CLUSTERED (id_alta) 
)
ON altas_fecha (fecha_alta); --ESTO DA ERROR
GO


INSERT INTO [autoescuelaP].[dbo].[cliente] 
    ([DNI_cliente], [N_cliente], [Apel1_cliente], [Apel2_cliente], 
     [Dir_cliente], [Email_cliente], [Telf_cliente], [localidad_cod_localidad])
VALUES
    ('12345618A', 'Carlos', 'García', 'López', 'Calle Mayor 12', 'carlos.garcia@email.com', '612345678', 1),
    ('23456789Z', 'Laura', 'Fernández', 'Ruiz', 'Avenida del Sol 8', 'laura.fernandez@email.com', '623456789', 2),
    ('34567890X', 'Miguel', 'Martínez', 'Sánchez', 'Paseo de la Castellana 20', 'miguel.martinez@email.com', '634567890', 3),
    ('45678901C', 'Ana', 'Hernández', 'Gómez', 'Calle de la Luna 5', 'ana.hernandez@email.com', '645678901', 4),
    ('56789012V', 'Javier', 'Pérez', 'Díaz', 'Plaza Mayor 3', 'javier.perez@email.com', '656789012', 5),
    ('67890123B', 'Sofía', 'López', 'Martín', 'Ronda Norte 15', 'sofia.lopez@email.com', '667890123', 1),
    ('78901234N', 'David', 'González', 'Jiménez', 'Calle Ancha 7', 'david.gonzalez@email.com', '678901234', 2),
    ('89012345M', 'Elena', 'Rodríguez', 'Moreno', 'Avenida de la Paz 10', 'elena.rodriguez@email.com', '689012345', 3),
    ('90123456K', 'Alejandro', 'Serrano', 'Álvarez', 'Calle Nueva 22', 'alejandro.serrano@email.com', '690123456', 4),
    ('11223344J', 'Marina', 'Díaz', 'Torres', 'Camino Real 9', 'marina.diaz@email.com', '611223344', 5),
    ('22334455H', 'Luis', 'Morales', 'Ortega', 'Plaza España 6', 'luis.morales@email.com', '622334455', 1),
    ('33445566G', 'Clara', 'Ruiz', 'Castro', 'Avenida Libertad 4', 'clara.ruiz@email.com', '633445566', 2),
    ('44556677F', 'Pablo', 'Jiménez', 'Santos', 'Calle Verde 18', 'pablo.jimenez@email.com', '644556677', 3),
    ('55667788D', 'Natalia', 'Ortega', 'Ramos', 'Paseo Azul 25', 'natalia.ortega@email.com', '655667788', 4),
    ('66778899S', 'Fernando', 'Torres', 'Vega', 'Camino Rojo 11', 'fernando.torres@email.com', '666778899', 5),
    ('77889900A', 'Lucía', 'Castro', 'Navarro', 'Calle del Mar 14', 'lucia.castro@email.com', '677889900', 1),
    ('88990011W', 'Hugo', 'Santos', 'Méndez', 'Avenida de los Olivos 17', 'hugo.santos@email.com', '688990011', 2),
    ('99001122Q', 'Isabel', 'Navarro', 'Peña', 'Plaza de la Fuente 2', 'isabel.navarro@email.com', '699001122', 3),
    ('10111213E', 'Sergio', 'Méndez', 'Luna', 'Ronda Este 8', 'sergio.mendez@email.com', '610111213', 4),
    ('11121314R', 'Eva', 'Peña', 'Cabrera', 'Calle del Parque 16', 'eva.pena@email.com', '611121314', 5),
    ('12131415E', 'Raúl', 'Luna', 'Nieto', 'Avenida del Río 19', 'raul.luna@email.com', '612131415', 1),
    ('13141516W', 'Beatriz', 'Cabrera', 'Molina', 'Calle del Bosque 21', 'beatriz.cabrera@email.com', '613141516', 2),
    ('14151617Q', 'Óscar', 'Nieto', 'Rey', 'Paseo del Sol 13', 'oscar.nieto@email.com', '614151617', 3),
    ('15161718A', 'Paula', 'Molina', 'Salas', 'Ronda del Sur 24', 'paula.molina@email.com', '615161718', 4),
    ('16171819P', 'Jorge', 'Rey', 'Campos', 'Plaza de la Luna 27', 'jorge.rey@email.com', '616171819', 5),
    ('17181920O', 'Alba', 'Salas', 'Crespo', 'Calle Ancha 30', 'alba.salas@email.com', '617181920', 1),
    ('18192021I', 'Manuel', 'Campos', 'Soto', 'Camino del Norte 12', 'manuel.campos@email.com', '618192021', 2),
    ('19202122U', 'Carmen', 'Crespo', 'Pascual', 'Avenida Central 23', 'carmen.crespo@email.com', '619202122', 3),
    ('20212223Y', 'Antonio', 'Soto', 'Rivas', 'Calle Pequeña 26', 'antonio.soto@email.com', '620212223', 4);
GO

-- Otro ejemplo
-- Vamos a particionar la tabla clientes por localidades

-- 1.- CREO FILEGROUPS

ALTER DATABASE [autoescuelaP] ADD FILEGROUP [Otras] 
GO 

ALTER DATABASE [autoescuelaP] ADD FILEGROUP [Coruna] 
GO 

ALTER DATABASE [autoescuelaP] ADD FILEGROUP [Lugo] 
GO 

ALTER DATABASE [autoescuelaP] ADD FILEGROUP [Orense]
GO

ALTER DATABASE [autoescuelaP] ADD FILEGROUP [Pontevedra]
GO


select * from sys.filegroups

GO

-- 2.- CREO LOS ARCHIVOS Y VINCULO LOS FILEGROUPS
-- Se crean archivos para añadir cada filegroup a un archivo


ALTER DATABASE [autoescuelaP] ADD FILE ( NAME = 'Otras', FILENAME = 'c:\DATA\otras', SIZE = 5MB, MAXSIZE = 100MB, FILEGROWTH = 2MB ) TO FILEGROUP [Otras] 
GO

ALTER DATABASE [autoescuelaP] ADD FILE ( NAME = 'Coruna', FILENAME = 'c:\DATA\coruna.ndf', SIZE = 5MB, MAXSIZE = 100MB, FILEGROWTH = 2MB ) TO FILEGROUP [Coruna] 
GO

ALTER DATABASE [autoescuelaP] ADD FILE ( NAME = 'Lugo', FILENAME = 'c:\DATA\lugo.ndf', SIZE = 5MB, MAXSIZE = 100MB, FILEGROWTH = 2MB ) TO FILEGROUP [Lugo] 
GO

ALTER DATABASE [autoescuelaP] ADD FILE ( NAME = 'Orense', FILENAME = 'c:\DATA\orense.ndf', SIZE = 5MB, MAXSIZE = 100MB, FILEGROWTH = 2MB ) TO FILEGROUP [Orense] 
GO

ALTER DATABASE [autoescuelaP] ADD FILE ( NAME = 'Pontevedra', FILENAME = 'c:\DATA\pontevedra.ndf', SIZE = 5MB, MAXSIZE = 100MB, FILEGROWTH = 2MB ) TO FILEGROUP [Pontevedra] 
GO

select file_id, name, physical_name
from sys.database_files
GO

-- 3.- CREO FUNCION PARTICION
-- en este caso segúnel código de la localidad

DROP PARTITION FUNCTION FN_Localidades;
GO

CREATE PARTITION FUNCTION FN_Localidades (integer) 
AS RANGE LEFT -- En este caso 
	FOR VALUES (1,2,3,4);
GO

-- 4.- CREO EL ESQUEMA DE PARTICIÓN
-- Nos mapeará los registros según las particiones

CREATE PARTITION SCHEME SC_Localidades 
AS PARTITION FN_Localidades 
	TO (Coruna,Lugo,Orense,Pontevedra,Otras); 
GO


SELECT *,$Partition.FN_Localidades (localidad_cod_localidad) AS Partition
FROM cliente
ORDER BY Partition;
GO

-- Vamos a usar SPLIT para crear una partición para la localidad de MADRID
ALTER DATABASE [autoescuelaP] ADD FILEGROUP [Madrid] 
GO 

ALTER DATABASE [autoescuelaP] ADD FILE ( NAME = 'Madrid', FILENAME = 'c:\DATA\madrid.ndf', SIZE = 5MB, MAXSIZE = 100MB, FILEGROWTH = 2MB ) TO FILEGROUP [Madrid] 
GO

ALTER PARTITION SCHEME SC_Localidades 
NEXT USED Madrid;


ALTER PARTITION FUNCTION FN_Localidades() 
	SPLIT RANGE (5); 
GO 

SELECT *,$Partition.FN_Localidades (localidad_cod_localidad) AS Partition
FROM clientes
ORDER BY Partition;
GO

-- 1. Crear las tablas (asegurándonos de que tengan la misma estructura y la columna de partición correcta)
CREATE TABLE clientes (
    DNI_cliente VARCHAR(9),  
    N_cliente NVARCHAR(12),       
    Apel1_cliente NVARCHAR(12),   
    Apel2_cliente NVARCHAR(12),      
    Dir_cliente NVARCHAR(50),    
    Email_cliente NVARCHAR(30),   
    Telf_cliente NVARCHAR(16),   
    localidad_cod_localidad INT
) on Otras
-- Suponiendo que "clientes" no está particionada
;

CREATE TABLE cliente_espana (
    DNI_cliente VARCHAR(9),  
    N_cliente NVARCHAR(12),       
    Apel1_cliente NVARCHAR(12),   
    Apel2_cliente NVARCHAR(12),      
    Dir_cliente NVARCHAR(50),    
    Email_cliente NVARCHAR(30),   
    Telf_cliente NVARCHAR(16),   
    localidad_cod_localidad INT
) 
ON SC_Localidades (localidad_cod_localidad);  -- La columna de partición en cliente_espana

-- 2. INSERTAR DATOS EN LA TABLA "clientes" (NO PARTICIONADA)
INSERT INTO clientes (DNI_cliente, N_cliente, Apel1_cliente, Apel2_cliente, Dir_cliente, Email_cliente, Telf_cliente, localidad_cod_localidad)
VALUES
('12345678A', 'Carlos', 'García', 'López', 'Calle Mayor 10, Madrid', 'carlos.garcia@email.com', '612345678', 6),
('23456789B', 'María', 'Fernández', 'Martínez', 'Avenida Andalucía 25, Sevilla', 'maria.fernandez@email.com', '623456789', 6);

-- 3. MOVER LOS DATOS DE "clientes" A "cliente_espana" USANDO SWITCH
ALTER TABLE clientes
SWITCH TO cliente_espana PARTITION 6;  -- Asegúrate de que los datos estén dentro de la partición correcta
GO


INSERT INTO [autoescuelaP].[dbo].[clientes] 
    ([DNI_cliente], [N_cliente], [Apel1_cliente], [Apel2_cliente], 
     [Dir_cliente], [Email_cliente], [Telf_cliente], [localidad_cod_localidad])
VALUES
    ('12345618A', 'Carlos', 'García', 'López', 'Calle Mayor 12', 'carlos.garcia@email.com', '612345678', 6),
    ('23456789Z', 'Laura', 'Fernández', 'Ruiz', 'Avenida del Sol 8', 'laura.fernandez@email.com', '623456789', 6),
    ('34567890X', 'Miguel', 'Martínez', 'Sánchez', 'Paseo de la Castellana 20', 'miguel.martinez@email.com', '634567890', 6),
    ('45678901C', 'Ana', 'Hernández', 'Gómez', 'Calle de la Luna 5', 'ana.hernandez@email.com', '645678901', 6),
    ('56789012V', 'Javier', 'Pérez', 'Díaz', 'Plaza Mayor 3', 'javier.perez@email.com', '656789012', 6),
    ('67890123B', 'Sofía', 'López', 'Martín', 'Ronda Norte 15', 'sofia.lopez@email.com', '667890123', 6),
    ('78901234N', 'David', 'González', 'Jiménez', 'Calle Ancha 7', 'david.gonzalez@email.com', '678901234', 6),
    ('89012345M', 'Elena', 'Rodríguez', 'Moreno', 'Avenida de la Paz 10', 'elena.rodriguez@email.com', '689012345', 6),
    ('90123456K', 'Alejandro', 'Serrano', 'Álvarez', 'Calle Nueva 22', 'alejandro.serrano@email.com', '690123456', 6);
GO

drop table clientes;
drop table cliente_espana;
go


SELECT *,$Partition.FN_altas_fecha(fecha_alta) AS Partition
FROM Altas_matricula
GO

--TABLAS TEMPORALES


ALTER TABLE dbo.Contrato
ADD 
    SysStartTime   DATETIME2 GENERATED ALWAYS AS ROW START NOT NULL,  
    SysEndTime     DATETIME2 GENERATED ALWAYS AS ROW END NOT NULL,  
    PERIOD FOR SYSTEM_TIME (SysStartTime, SysEndTime);  
GO
ALTER TABLE dbo.Contrato  
SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.Historial_contrato));
GO


DROP TABLE contratos;
GO

CREATE TABLE [dbo].[contratos](
	[ID_contrato] [int] NOT NULL PRIMARY KEY,
	[Cargo] [nvarchar](18) NULL,
	[T_contrato] [nvarchar](12) NULL,
	[T_jornada] [nvarchar](12) NULL,
	[Sueldo] [decimal](10, 2) NULL,
	[Antiguedad] [nvarchar](9) NULL,
	[profesor_profesor_DNI_profe] [varchar](9) NOT NULL,
	    SysStartTime   DATETIME2 GENERATED ALWAYS AS ROW START NOT NULL,  
		SysEndTime     DATETIME2 GENERATED ALWAYS AS ROW END NOT NULL,  
		PERIOD FOR SYSTEM_TIME (SysStartTime, SysEndTime))  
 
WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.contratos_historial));  
GO


INSERT INTO [dbo].[contratos] (ID_contrato, Cargo, T_contrato, T_jornada, Sueldo, Antiguedad, profesor_profesor_DNI_profe)
VALUES 
(1, 'Profesor', 'Fijo', 'Completa', 2200.50, '10 años', '12345678A'),
(2, 'Profesor', 'Temporal', 'Parcial', 1500.00, '3 años', '23456789B'),
(3, 'Profesor', 'Fijo', 'Completa', 2500.75, '7 años', '34567890C'),
(4, 'Admin', 'Fijo', 'Completa', 2700.00, '5 años', '45678901D'),
(5, 'Profesor', 'Temporal', 'Parcial', 1800.30, '2 años', '56789012E'),
(6, 'Coordinador', 'Fijo', 'Completa', 3000.00, '12 años', '67890123F'),
(7, 'Profesor', 'Fijo', 'Parcial', 2000.50, '8 años', '78901234G'),
(8, 'Profesor', 'Temporal', 'Completa', 1600.80, '4 años', '89012345H'),
(9, 'Secretario', 'Fijo', 'Completa', 1900.90, '6 años', '90123456I'),
(10, 'Profesor', 'Temporal', 'Parcial', 1400.75, '1 año', '11234567J'),
(11, 'J.Estudios', 'Fijo', 'Completa', 3500.00, '15 años', '22345678K'),
(12, 'Profesor', 'Temporal', 'Parcial', 1750.60, '3 años', '33456789L'),
(13, 'Contable', 'Fijo', 'Completa', 2800.00, '9 años', '44567890M'),
(14, 'Profesor', 'Fijo', 'Completa', 2300.40, '11 años', '55678901N'),
(15, 'Profesor', 'Temporal', 'Parcial', 1550.20, '2 años', '66789012O');
GO



SELECT * FROM contratos;
GO

-- Hacemos modificaciones en antiguedad y sueldos

UPDATE [dbo].[contratos]
SET Sueldo = 3500.75, Antiguedad = '18 años'
WHERE ID_contrato = 1;

UPDATE [dbo].[contratos]
SET Sueldo = 4600.50, Antiguedad = '10 años'
WHERE ID_contrato = 2;
GO

UPDATE [dbo].[contratos]
SET Cargo = 'Coordinador'
WHERE ID_contrato = 1;
GO

PRINT GETUTCDATE()
GO

--Mar 22 2025 11:03AM
--Completion time: 2025-03-22T12:03:59.0400540+01:00


UPDATE [dbo].[contratos]
SET Sueldo = 3500.75, Antiguedad = '18 años'
WHERE ID_contrato = 1;

UPDATE [dbo].[contratos]
SET Sueldo = 4600.50, Antiguedad = '10 años'
WHERE ID_contrato = 2;
GO

PRINT GETUTCDATE()
GO
--Mar 22 2025 11:04AM
--Completion time: 2025-03-22T12:04:42.3275737+01:00


SELECT * FROM contratos_historial;
GO

SELECT * FROM contratos_historial
WHERE ID_contrato = 1;
GO

DELETE FROM contratos
WHERE ID_contrato = 1;
GO

SELECT * FROM contratos;
GO

SELECT * FROM contratos_historial;
GO

-- Cambios sufridos en la tabla a lo largo del tiempo
SELECT * FROM contratos
FOR system_time ALL
GO

-- Estado de la tabla en un momento determinado
SELECT * FROM contratos
FOR system_time AS OF '2025-03-22T10:57:40'
ORDER BY ID_contrato;
GO


SELECT * FROM contratos
FOR system_time AS OF '2025-03-22T12:36:40'
ORDER BY ID_contrato;
GO

SELECT * FROM contratos
FOR system_time FROM '2025-03-21' TO '2025-03-23'
ORDER BY ID_contrato;
GO


SELECT * FROM contratos
FOR system_time BETWEEN '2025-03-21' AND '2025-03-23'
ORDER BY ID_contrato;
GO

SELECT * FROM contratos
FOR system_time CONTAINED IN ('2025-03-21','2025-03-23')
WHERE T_contrato = 'Temporal';
GO

-- TABLAS EN MEMORIA

-- 1. Creamos el filegroup para memoria optimizada
ALTER DATABASE AutoescuelaP
ADD FILEGROUP AutoescuelaP_mod CONTAINS MEMORY_OPTIMIZED_DATA;
GO

-- 2. Añadimos el archivo
ALTER DATABASE AutoescuelaP ADD FILE(
    NAME = 'AutoescuelaP_mod',
    FILENAME = 'C:\Data\AutoescuelaP_mod.ndf'
)
TO FILEGROUP AutoescuelaP_mod;
GO
/*
SELECT name, type_desc 
FROM sys.filegroups;

ALTER DATABASE AutoescuelaP REMOVE FILEGROUP AutoescuelaP;
GO
*/

-- 3. Creamos la tabla en disco 
CREATE TABLE dbo.ReservasClasesPracticas_Disco
(
    ID INT IDENTITY PRIMARY KEY,
    Alumno NVARCHAR(20),
    Fecha DATETIME,
    Vehiculo NVARCHAR(20),
    Estado NVARCHAR(10)
);

-- 4. Creamos la tabla en memoria 
-- IMPORTANTE acordarse de: FileGroup MEMORY_OPTIMIZED_DATA
ALTER DATABASE CURRENT ADD FILEGROUP PracticasFG CONTAINS MEMORY_OPTIMIZED_DATA;
ALTER DATABASE CURRENT ADD FILE (NAME='Practicas_Data', FILENAME='C:\Data\Practicas_Data') TO FILEGROUP PracticasFG;

CREATE TABLE dbo.ReservasClasesPracticas_Memoria(
    ID INT IDENTITY PRIMARY KEY NONCLUSTERED,
    Alumno NVARCHAR(20),
    Fecha DATETIME,
    Vehiculo NVARCHAR(20),
    Estado NVARCHAR(10)
) WITH (MEMORY_OPTIMIZED = ON, DURABILITY = SCHEMA_AND_DATA);
GO
-- 5. Creamos procedimiento para insertar 50.000 registros, seleccionando tabla y calculando tiempo
CREATE OR ALTER PROCEDURE GenerarReservasPracticas
    @TipoTabla NVARCHAR(10) = 'DISCO' -- 'DISCO' o 'MEMORIA'
AS
BEGIN
    DECLARE @contador INT = 1;
    DECLARE @Alumno NVARCHAR(20);
    DECLARE @Fecha DATETIME;
    DECLARE @Vehiculo NVARCHAR(20);
    DECLARE @Estado NVARCHAR(10);
    DECLARE @Inicio DATETIME = GETDATE();

    WHILE @contador <= 50000
    BEGIN
        SET @Alumno = (SELECT TOP 1 Nombre FROM (VALUES ('Borja'), ('Ana'), ('Carlos'), ('Marta'), 
                                  ('Javier'), ('Lucía'), ('David')) AS N(Nombre) ORDER BY NEWID());
        
        SET @Fecha = DATEADD(DAY, FLOOR(RAND() * 30), GETDATE());
        
        SET @Vehiculo = RIGHT('0000' + CAST(FLOOR(RAND() * 10000) AS NVARCHAR(4)), 4) + '-' + 
                       CHAR(65 + FLOOR(RAND() * 26)) + 
                       CHAR(65 + FLOOR(RAND() * 26)) + 
                       CHAR(65 + FLOOR(RAND() * 26));
        
        SET @Estado = (SELECT TOP 1 Estado FROM (VALUES ('Pendiente'), ('Completada'), ('Cancelada')) 
                      AS E(Estado) ORDER BY NEWID());

        IF @TipoTabla = 'DISCO'
            INSERT INTO dbo.ReservasClasesPracticas_Disco (Alumno, Fecha, Vehiculo, Estado)
            VALUES (@Alumno, @Fecha, @Vehiculo, @Estado);
        ELSE
            INSERT INTO dbo.ReservasClasesPracticas_Memoria (Alumno, Fecha, Vehiculo, Estado)
            VALUES (@Alumno, @Fecha, @Vehiculo, @Estado);

        SET @contador += 1;
    END;

    DECLARE @TiempoEjecucion INT = DATEDIFF(MILLISECOND, @Inicio, GETDATE());
    SELECT CONCAT('Tiempo de ejecución: ', @TiempoEjecucion, ' ms') AS Resultado;
END;
GO

--Realizamos las pruebas

-- Insertar en disco
EXEC GenerarReservasPracticas @TipoTabla = 'DISCO';
GO
-- Resultado
--Tiempo de ejecución: 67900 ms

-- Insertar en memoria
EXEC GenerarReservasPracticas @TipoTabla = 'MEMORIA';
GO
-- Resultado
--Tiempo de ejecución: 64413 ms

SELECT name, type_desc 
FROM sys.tables 
WHERE name = 'ReservasClasesPracticas';
GO


SELECT * FROM ReservasClasesPracticas;
GO


