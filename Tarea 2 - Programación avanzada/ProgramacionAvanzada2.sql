USE autoescuelaP;
GO

-- BASES DE DATOS CONTENIDAS
-- Activamos opciones avanzadas
	EXEC sp_configure 'show advanced options' 1
	GO
	
-- Activamos BD contenidas
	EXEC sp_configure 'contained database authentication', 1
	GO

-- Modificamos la base de datos para convertirla en contenida
	ALTER DATABASE [autoescuelaP]
	SET CONTAINMENT = PARTIAL;




-- BLOB (LOCAL)

-- Probamos a activar cmdshell y a crear la carpeta
EXECUTE sp_configure 'show advanced options',1;
RECONFIGURE;
GO

EXECUTE sp_configure 'xp_cmdshell',1;
RECONFIGURE
GO

EXECUTE xp_cmdshell 'mkdir c:\Fotos_profesores\';
GO

-- Dentro de nuestra base de datos, modificamos la tabla profesores para  añadir un campo para las fotos
ALTER TABLE profesor
ADD fotografía VARBINARY(MAX),
    extension NVARCHAR(10);

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

SELECT profesor_N_profe, profesor_Apel1_profe, profesor_Apel2_profe, fotografía, extension FROM profesor;
GO

-- FILESTREAM
-- activamos FILESTREAM (si no lo hemos hecho en configuration manager)
EXEC sp_configure filestream_access_level, 2
RECONFIGURE
GO
-- Creamos el filegroup Fotoprofes para organizar las fotografías
ALTER DATABASE [autoescuelap]
ADD FILEGROUP [Fotoprofes] CONTAINS FILESTREAM;
GO

-- añadimos el fichero donde vamos a almacenar el filegroup (las imagenes)
ALTER DATABASE [autoescuelap]
	ADD FILE (NAME='FOTOGRAFIAS',
	FILENAME = 'C:\FOTOGRAFIAS')
	TO FILEGROUP [Fotoprofes]
GO

-- Creamos la tabla orla para evitar conflictos
CREATE TABLE Orla
(ID INT IDENTITY,
 ID2 UNIQUEIDENTIFIER ROWGUIDCOL NOT NULL UNIQUE,
 nombre varchar(255),
 fotografía VARBINARY(MAX) FILESTREAM,
 extension CHAR(5)
 )
 GO

 -- Insertamos los datos
