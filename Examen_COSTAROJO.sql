/*
Creamos una nueva BD con el nombre vuestras iniciales + Fecha de Hoy
Generar Tabla usando como base la Tabla AdventureWorks.Sales.SalesOrderHeader
(Ver Script adjunta)

-- Crear PARTICIÓN con campo orderdate. Demostrar Funcionamiento.
   Realizar las operaciones : SPLIT - TRUNCATE (por ejemplo, la Partición final)
*/


USE AdventureWorks2022;
GO

SELECT * FROM AdventureWorks2022.Sales.SalesOrderHeader;
GO

-- Creamos la BD
USE MASTER
GO

DROP DATABASE IF EXISTS BC_20250328;
GO
CREATE DATABASE BC_20250328;
GO
USE BC_20250328;
GO

-- Creamos carpeta para guardar los archivos
EXECUTE sp_configure 'xp_cmdshell', 1;
GO
RECONFIGURE;
GO
xp_cmdshell 'mkdir C:\DATA_E\'
GO


-- Crear los filegroups necesarios
ALTER DATABASE BC_20250328 ADD FILEGROUP FG_Antiguas;
ALTER DATABASE BC_20250328 ADD FILEGROUP FG_Sales2013;
ALTER DATABASE BC_20250328 ADD FILEGROUP FG_Sales2014;
GO

-- Añadir archivos a cada filegroup (ajusta las rutas según tu sistema)
ALTER DATABASE BC_20250328 
ADD FILE (NAME = N'Antiguas', FILENAME = N'C:\Data_E\Antiguas.ndf', SIZE = 5MB) TO FILEGROUP FG_Antiguas;

ALTER DATABASE BC_20250328 
ADD FILE (NAME = N'Sales2013', FILENAME = N'C:\Data_E\Sales2013.ndf', SIZE = 5MB) TO FILEGROUP FG_Sales2013;

ALTER DATABASE BC_20250328 
ADD FILE (NAME = N'Sales2014', FILENAME = N'C:\Data_E\Sales2014.ndf', SIZE = 5MB) TO FILEGROUP FG_Sales2014;
GO

-- Crear la función de partición por OrderDate
CREATE PARTITION FUNCTION PF_OrderDateRange (datetime)
AS RANGE RIGHT FOR VALUES 
('2013-01-01', '2014-01-01');
GO


-- Crear el esquema de partición
CREATE PARTITION SCHEME PS_OrderDateRange
AS PARTITION PF_OrderDateRange
TO (FG_Antiguas, FG_Sales2013, FG_Sales2014);
GO


-- Crear la tabla particionada
CREATE TABLE dbo.BC_20250328 (
    [SalesOrderID] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
    [RevisionNumber] [tinyint] NOT NULL DEFAULT 0,
    [OrderDate] [datetime] NOT NULL, -- Cambiado a NOT NULL para la PK
    [DueDate] [datetime] NOT NULL,
    [ShipDate] [datetime] NULL,
    [Status] [tinyint] NOT NULL DEFAULT 1,
    [OnlineOrderFlag] [INT] NOT NULL DEFAULT 0,
    [SalesOrderNumber] AS (isnull(N'SO'+CONVERT([nvarchar](23),[SalesOrderID]),N'*** ERROR ***')),
    [PurchaseOrderNumber] [VARCHAR](25) NULL, -- Añadida longitud
    [AccountNumber] [VARCHAR](15) NULL, -- Añadida longitud
    [CustomerID] [int] NOT NULL,
    [SalesPersonID] [int] NULL,
    [TerritoryID] [int] NULL,
    [BillToAddressID] [int] NOT NULL,
    [ShipToAddressID] [int] NOT NULL,
    [ShipMethodID] [int] NOT NULL DEFAULT 1,
    [CreditCardID] [int] NULL,
    [CreditCardApprovalCode] [varchar](15) NULL,
    [CurrencyRateID] [int] NULL,
    [SubTotal] [money] NOT NULL DEFAULT 0,
    [TaxAmt] [money] NOT NULL DEFAULT 0,
    [Freight] [money] NOT NULL DEFAULT 0,
    [TotalDue] AS (isnull(([SubTotal]+[TaxAmt])+[Freight],(0))),
    [Comment] [nvarchar](128) NULL,
    [rowguid] [uniqueidentifier] ROWGUIDCOL NOT NULL DEFAULT NEWID(),
    [ModifiedDate] [datetime] NOT NULL DEFAULT GETDATE(),
    CONSTRAINT PK_BC_20250324_SalesOrderID PRIMARY KEY CLUSTERED (SalesOrderID, OrderDate)
) ON PS_OrderDateRange(OrderDate);
GO


-- Insertamos los datos
SELECT *
INTO BC_20250328
FROM [AdventureWorks2022].[Sales].[SalesOrderHeader];
GO

-- Da error porque la tabla está creada

DROP TABLE BC_20250328;
GO

SELECT *
INTO BC_20250328
FROM [AdventureWorks2022].[Sales].[SalesOrderHeader];
GO

-- Comprobamos
select p.partition_number, p.rows from sys.partitions p 
inner join sys.tables t 
on p.object_id=t.object_id and t.name = 'BC_20250328' 
GO

-- No funciona la partición
-- Copiamos y pegamos datos directamente

SET IDENTITY_INSERT [dbo].[BC_20250328] ON;

INSERT INTO dbo.BC_20250328 (
    SalesOrderID,
    RevisionNumber,
    OrderDate,
    DueDate,
    ShipDate,
    Status,
    OnlineOrderFlag,
    PurchaseOrderNumber,
    AccountNumber,
    CustomerID,
    SalesPersonID,
    TerritoryID,
    BillToAddressID,
    ShipToAddressID,
    ShipMethodID,
    CreditCardID,
    CreditCardApprovalCode,
    CurrencyRateID,
    SubTotal,
    TaxAmt,
    Freight,
    Comment,
    rowguid,
    ModifiedDate
)
SELECT 
    SalesOrderID,
    RevisionNumber,
    OrderDate,
    DueDate,
    ShipDate,
    Status,
    OnlineOrderFlag,
    PurchaseOrderNumber,
    AccountNumber,
    CustomerID,
    SalesPersonID,
    TerritoryID,
    BillToAddressID,
    ShipToAddressID,
    ShipMethodID,
    CreditCardID,
    CreditCardApprovalCode,
    CurrencyRateID,
    SubTotal,
    TaxAmt,
    Freight,
    Comment,
    rowguid,
    ModifiedDate
FROM AdventureWorks2022.Sales.SalesOrderHeader;

SET IDENTITY_INSERT [dbo].[BC_20250328] OFF;
GO


--Comprobamos
SELECT file_id, name, physical_name
FROM sys.database_files
GO

select p.partition_number, p.rows from sys.partitions p 
inner join sys.tables t 
on p.object_id=t.object_id and t.name = 'BC_20250328' 
GO



SELECT * FROM BC_20250328;  -- Ahora si funciona
GO



-- Realizar las operaciones : SPLIT - TRUNCATE (por ejemplo, la Partición final)

ALTER DATABASE [BC_20250328] ADD FILEGROUP [Sales2012] 
GO 


ALTER DATABASE [BC_20250328] ADD FILE ( NAME = 'Sales2012', FILENAME = 'c:\DATA_E\sales2012.ndf', SIZE = 5MB, MAXSIZE = 100MB, FILEGROWTH = 2MB ) TO FILEGROUP [Sales2012] 
GO


ALTER PARTITION SCHEME  PS_OrderDateRange
NEXT USED Sales2012;


ALTER PARTITION FUNCTION PF_OrderDateRange() 
   SPLIT RANGE ('2012-01-01');


   SELECT *,$Partition.PF_OrderDateRange(OrderDate) AS Partition
FROM BC_20250328
GO



TRUNCATE TABLE BC_20250328 WITH (PARTITIONS (1));
GO

   SELECT *,$Partition.PF_OrderDateRange(OrderDate) AS Partition
FROM BC_20250328
GO




----------------------------------------------------------------------------------
---------------------------------------------------------------------------------


/*  Queremos mantener información sobre la evolución de los Departamentos de nuestra empresa a lo largo del tiempo.
	Estructura de la tabla Departamento:
		DeptID,  DeptName, DepCreado , NumEmpleados
	Crear TABLA TEMPORAL (VERSIÓN DEL SISTEMA) y demostrar funcionamiento con un par de consultas diferentes
 (usando los Operadores específicos de estas Tablas).
*/

USE master
GO

--Creo la base de datos
CREATE DATABASE FWirtz
ON PRIMARY ( NAME = 'FWirtz',
FILENAME = 'C:\Data_E\FWirtz.mdf' ,
SIZE = 15360KB , MAXSIZE = UNLIMITED, FILEGROWTH = 0) LOG ON ( NAME = 'FWirtz_log',
FILENAME = 'C:\Data_E\FWirtz_log.ldf' ,
SIZE = 10176KB , MAXSIZE = 2048GB , FILEGROWTH = 10%)
GO

USE FWirtz;
GO

-- Creamos la tabla departamento con tabla temporal versión sistema
CREATE TABLE Departamento (
    DeptID INT PRIMARY KEY,
    DeptName VARCHAR(100) NOT NULL,
    DepCreado DATE NOT NULL,
    NumEmpleados INT NOT NULL,
    SysStartTime DATETIME2 GENERATED ALWAYS AS ROW START HIDDEN NOT NULL,
    SysEndTime DATETIME2 GENERATED ALWAYS AS ROW END HIDDEN NOT NULL,
    PERIOD FOR SYSTEM_TIME (SysStartTime, SysEndTime)
)  
WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.Departamentos_Historial));
GO	

SELECT * FROM Departamento;
GO

-- Insertamos datos
INSERT INTO Departamento (DeptID, DeptName, DepCreado, NumEmpleados)
VALUES 
    (1, 'Recursos Humanos', '2015-01-10', 10),
    (2, 'IT', '2018-03-15', 25),
    (3, 'Ventas', '2020-07-01', 30);
GO

SELECT * FROM Departamento;
GO

PRINT GETUTCDATE() -- 5:01PM
GO


-- Modificamos datos
UPDATE Departamento  --5:05PM 
SET NumEmpleados = 12 
WHERE DeptID = 1;



UPDATE Departamento 
SET NumEmpleados = 27 
WHERE DeptID = 2;


SELECT * FROM Departamento;
GO	

PRINT GETUTCDATE()
GO


INSERT INTO Departamento (DeptID, DeptName, DepCreado, NumEmpleados) --5:08PM
VALUES 
    (4, 'Marketing', '2016-01-10', 4),
    (5, 'Internacional', '2018-03-17', 5);
GO


-- Modificamos datos
UPDATE Departamento 
SET NumEmpleados = 42 
WHERE DeptID = 1;



UPDATE Departamento 
SET NumEmpleados = 47 
WHERE DeptID = 2;


-- Selecciona los registros de departamento RRHH para ver los cambios que ha sufrido
SELECT * 
FROM Departamento 
FOR SYSTEM_TIME ALL
WHERE DeptID = 1;

-- Consultamos los cambios registradosdesde que hay registros
SELECT * 
FROM Departamentos_Historial; 
GO


-- Cuando el departamento de RRHH tuvo menos de 40 empleados
SELECT DeptID, DeptName, NumEmpleados, SysStartTime, SysEndTime
FROM Departamento
FOR SYSTEM_TIME ALL
WHERE DeptName = 'Recursos Humanos'
AND NumEmpleados < 40
ORDER BY SysStartTime;



-----------------------------------------------------------------------------
-----------------------------------------------------------------------------



/* Crear una Función RLS (ROW LEVEL SECURITY) para controlar :
 	1 Consulta y después INSERT - UPDATE - DELETE
 	sobre una Tabla Alumnos.
 	Cada Tutor puede realizar CRUD sobre sus alumnos y ele Jefe de estudios puede realizar operaciones con todos los alumnos.
*/

USE master;
GO

-- Creamos la base de datos
DROP DATABASE IF EXISTS TUTORIA
GO

CREATE DATABASE TUTORIA
ON PRIMARY ( NAME = 'TUTORIA',
FILENAME = 'C:\Data_E\TUTORIA.mdf' ,
SIZE = 15360KB , MAXSIZE = UNLIMITED, FILEGROWTH = 0) LOG ON ( NAME = 'TUTORIA_log',
FILENAME = 'C:\Data_E\TUTORIA_log.ldf' ,
SIZE = 10176KB , MAXSIZE = 2048GB , FILEGROWTH = 10%)
GO

USE TUTORIA
GO

CREATE USER Tutor1 WITHOUT LOGIN;
CREATE USER Tutor2 WITHOUT LOGIN;
CREATE USER Tutor3 WITHOUT LOGIN;
CREATE USER JefeEstudios WITHOUT LOGIN;
go

DROP TABLE IF EXISTS dbo.Alumnos
go
CREATE TABLE dbo.Alumnos
(
    AlumnoId INT IDENTITY(1,1),
    Nombre   NVARCHAR(100),
    Tutor  sysname  
)
GO

INSERT INTO Alumnos (Nombre,Tutor)
Values('Pepe', 'Tutor1'),('Raul','Tutor1'),('Ana','Tutor2'),
      ('Juan','Tutor3'),('Julia','Tutor3');
GO

SELECT * FROM Alumnos;
GO

-- Concedemos permisos a los usuarios
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.Alumnos TO Tutor1;
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.Alumnos TO Tutor2;
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.Alumnos TO Tutor3;
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.Alumnos TO JefeEstudios;
GO


-- Creamos función de seguridad
CREATE OR ALTER FUNCTION dbo.fn_seguridad_profesor(@Tutor AS SYSNAME)
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN (
    SELECT 1 AS acceso
    WHERE USER_NAME() = @Tutor
    OR USER_NAME() = 'JefeEstudios'
);
GO


-- Creamos política de seguridad
CREATE SECURITY POLICY PoliticaSeguridadPractica
ADD FILTER PREDICATE dbo.fn_seguridad_profesor(Tutor) ON dbo.Alumnos,
ADD BLOCK PREDICATE dbo.fn_seguridad_profesor(Tutor) ON dbo.Alumnos
WITH (STATE = ON);
GO

-- Comprobamos
EXECUTE AS USER = 'Tutor1'; -- Solo se ven sus alumnos
SELECT * FROM Alumnos
GO

REVERT
GO

EXECUTE AS USER = 'JefeEstudios';  -- Tiene permisos
SELECT * FROM Alumnos
GO

DROP DATABASE TUTORIA;
GO

REVERT
GO
PRINT USER;
GO

EXECUTE AS USER = 'JefeEstudios';  -- Tiene permisos, deja añadir alumnos
INSERT INTO Alumnos (Nombre,Tutor)
Values('Pepe', 'Tutor2'),('Raul','Tutor2');
GO

REVERT
GO
PRINT USER;
GO

EXECUTE AS USER = 'Tutor3';  -- No tiene permisos, deja añadir alumnos
INSERT INTO Alumnos (Nombre,Tutor)
Values('Pepe', 'Tutor1'),('Raul','Tutor1');
GO

REVERT
GO
PRINT USER;
GO

EXECUTE AS USER = 'Tutor1';  -- Tiene permisos, deja añadir alumnos porque es su tutor
INSERT INTO Alumnos (Nombre,Tutor)
Values('Pepe', 'Tutor1'),('Raul','Tutor1');
GO

