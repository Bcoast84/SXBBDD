-- SEGURIDAD
use autoescuelaP;
GO

DROP PROCEDURE SPactualiza_Sueldo;
GO

DROP PROCEDURE SPactualiza_Sueldo_Encrypt;
GO

--Sin encriptación (todo el mundo puede ver el código del procedimiento)
CREATE PROCEDURE SPactualiza_Sueldo
    @DNI_profesor VARCHAR(9),
    @Nuevo_sueldo DECIMAL(10,2)
AS
BEGIN
    UPDATE contrato
    SET Sueldo = @Nuevo_sueldo
    WHERE profesor_profesor_DNI_profe = @DNI_profesor
END
GO
-- Con encriptación (no puede verse el código del procedimiento)
CREATE PROCEDURE SPactualiza_Sueldo_Encrypt
    @DNI_profesor VARCHAR(9),
    @Nuevo_sueldo DECIMAL(10,2)
	WITH ENCRYPTION
AS
BEGIN
    UPDATE contrato
    SET Sueldo = @Nuevo_sueldo
    WHERE profesor_profesor_DNI_profe = @DNI_profesor
END
GO

EXEC sp_helptext 'SPactualiza_Sueldo';
GO

EXEC sp_helptext 'SPactualiza_Sueldo_Encrypt';
GO

-- Otra prueba
CREATE PROCEDURE sp_EliminarVehiculo  
    @Matricula NVARCHAR(10)  
WITH ENCRYPTION  -- Con encriptación
AS  
BEGIN  
    SET NOCOUNT ON;  
    -- Verificar si la matrícula existe en la tabla
    IF EXISTS (SELECT 1 FROM vehiculo WHERE Matricula_vehiculo = @Matricula)  
    BEGIN  
        DELETE FROM vehiculo WHERE Matricula_vehiculo = @Matricula;  
        PRINT 'El vehículo con matrícula ' + @Matricula + ' ha sido eliminado correctamente.';  
    END  
    ELSE  
    BEGIN  
        PRINT 'La matrícula introducida no existe en la base de datos.';  
    END  
END;

EXEC sp_helptext sp_EliminarVehiculo;
GO

--Encriptar Columna

-- Creamos logins para los profesores
CREATE LOGIN profe1 WITH password = 'Abcd1234.'
GO
CREATE LOGIN profe2 WITH password = 'Abcd1234.'
GO

-- vinculamos los logins a los usuarios
CREATE USER profe1 FOR LOGIN profe1;
CREATE USER profe2 FOR LOGIN profe2;
GO

REVERT
GO
-- Concedemos permisos
GRANT SELECT, INSERT, DELETE ON alumnos TO profe1, profe2;
GO

-- Se borra la master key
DROP MASTER KEY
GO
-- Se crea la master key
CREATE master KEY encryption BY password = 'Abcd1234.'
GO

-- Se comprueba
SELECT name KeyName,
	symmetric_key_id KeyID,
	key_length KeyLength,
	algorithm_desc KeyAlgorithm
FROM sys.symmetric_keys;
GO

-- Se crea el certificado
CREATE CERTIFICATE profe1cert AUTHORIZATION profe1
WITH subject = 'Abcd1234.', EXPIRY_DATE = '2025-12-31';  
GO
CREATE CERTIFICATE profe2cert AUTHORIZATION profe2
WITH subject = 'Abcd1234.', EXPIRY_DATE = '2025-12-31';
GO

-- Comprobamos
SELECT name CertName,
	certificate_id CertID,
	pvt_key_encryption_type_desc EncryptType,
	issuer_name Issuer
FROM sys.certificates;
GO

-- Creo la clave simétrica
CREATE SYMMETRIC KEY SK_01
	WITH ALGORITHM = AES_256
	ENCRYPTION BY CERTIFICATE profe1cert;
	GO

CREATE SYMMETRIC KEY SK_02
	WITH ALGORITHM = AES_256
	ENCRYPTION BY CERTIFICATE profe2cert;
	GO

-- Comprobamos
SELECT name KeyName,
	symmetric_key_id KeyID,
	key_length KeyLength,
	algorithm_desc KeyAlgorithm
FROM sys.symmetric_keys;
GO

-- Concedemos permisos a profe1 y profe2 sobre clave y certificados
GRANT VIEW DEFINITION ON CERTIFICATE::profe1cert TO profe1
GO
GRANT VIEW DEFINITION ON SYMMETRIC KEY::SK_01 TO profe1
GO

GRANT VIEW DEFINITION ON CERTIFICATE::profe2cert TO profe2
GO
GRANT VIEW DEFINITION ON SYMMETRIC KEY::SK_02 TO profe2
GO

-- Nos da error porque no podemos asignar permisos al propietario del certificado

PRINT USER;
GO

SELECT 
    name AS Usuario, 
    type_desc AS Tipo, 
    is_fixed_role AS RolFijo 
FROM sys.database_principals 
WHERE name IN ('profe1', 'profe2');

SELECT name AS Certificado, principal_id AS PropietarioID
FROM sys.certificates
WHERE name IN ('profe1cert', 'profe2cert');


REVERT
GO
-- Creamos la tabla alumnos que será una copia de la tabla clientes
DROP TABLE alumnos;
GO

CREATE TABLE [autoescuelaP].[dbo].[alumnos] (
    [DNI_cliente] VARCHAR(9) PRIMARY KEY,
    [N_cliente] VARCHAR(50) NOT NULL,
    [Apel1_cliente] VARCHAR(50) NOT NULL,
    [Apel2_cliente] VARCHAR(50),
    [Dir_cliente] VARBINARY(MAX),       
    [Email_cliente] VARCHAR(100),
    [Telf_cliente] VARBINARY(MAX),     
    [localidad_cod_localidad] INT
);
GO
-- Concedemos permisos
GRANT SELECT, INSERT, DELETE ON alumnos TO profe1, profe2;
GO

-- impersonamos
EXEC AS User = 'profe1';
GO

-- Abrimos la clave simétrica
OPEN SYMMETRIC KEY SK_01
	DECRYPTION BY CERTIFICATE profe1cert
GO

SELECT * FROM sys.openkeys
GO

-- Insertamos datos desde profe1 encriptando teléfono y dirección

INSERT INTO [autoescuelaP].[dbo].[alumnos] (
    [DNI_cliente],
    [N_cliente],
    [Apel1_cliente],
    [Apel2_cliente],
    [Dir_cliente],
    [Email_cliente],
    [Telf_cliente],
    [localidad_cod_localidad]
)
VALUES
(
    '12345678A',  
    'Carlos',
    'García',
    'López',
    EncryptByKey(Key_GUID('SK_01'), 'Calle Gran Vía 123, Madrid'),  
    'carlos.garcia@mail.com',
    EncryptByKey(Key_GUID('SK_01'), '637345678'), 
    28001  
),
(
    '87654321B',
    'Laura',
    'Martínez',
    'Sánchez',
    EncryptByKey(Key_GUID('SK_01'), 'Avenida Diagonal 456, Barcelona'),
    'laura.martinez@mail.com',
    EncryptByKey(Key_GUID('SK_01'), '633456789'),
    08001  
),
(
    '11223344C',
    'Miguel',
    'Fernández',
    'Rodríguez',
    EncryptByKey(Key_GUID('SK_01'), 'Plaza del Ayuntamiento 7, Valencia'),
    'miguel.fernandez@mail.com',
    EncryptByKey(Key_GUID('SK_01'), '663123456'),
    46001  
);

CLOSE SYMMETRIC KEY SK_01;
GO

REVERT;
GO

EXEC AS User = 'profe2';
GO
OPEN SYMMETRIC KEY SK_02 DECRYPTION BY CERTIFICATE profe2cert;
GO

INSERT INTO [autoescuelaP].[dbo].[alumnos] (
    [DNI_cliente],
    [N_cliente],
    [Apel1_cliente],
    [Apel2_cliente],
    [Dir_cliente],
    [Email_cliente],
    [Telf_cliente],
    [localidad_cod_localidad]
)
VALUES
(
    '55443322L',  
    'Ana',
    'Ruiz',
    'Gómez',
    EncryptByKey(Key_GUID('SK_02'), 'Calle Sierpes 45, Sevilla'),  
    'ana.ruiz@hotmail.com',
    EncryptByKey(Key_GUID('SK_02'), '654987321'),  
    41001  
),
(
    '98765432M',
    'Javier',
    'Hernández',
    'Díaz',
    EncryptByKey(Key_GUID('SK_02'), 'Gran Vía 22, Bilbao'),
    'javier.hernandez@gmail.com',
    EncryptByKey(Key_GUID('SK_02'), '688112233'),
    48001  
),
(
    '11223344N',
    'Sofía',
    'Jiménez',
    'Moreno',
    EncryptByKey(Key_GUID('SK_02'), 'Paseo Independencia 10, Zaragoza'),
    'sofia.jimenez@yahoo.com',
    EncryptByKey(Key_GUID('SK_02'), '676543219'),
    50001  
);
CLOSE SYMMETRIC KEY SK_02;
GO


REVERT
GO
PRINT USER
GO


SELECT * FROM alumnos;
GO

REVERT 
GO

EXEC AS User = 'profe1';
GO

-- Ejecutado como profe1:
OPEN SYMMETRIC KEY SK_01 DECRYPTION BY CERTIFICATE profe1cert;
SELECT 
    DNI_cliente,
    CONVERT(VARCHAR, DecryptByKey(Dir_cliente)) AS Direccion,
    CONVERT(VARCHAR, DecryptByKey(Telf_cliente)) AS Telefono
FROM alumnos;
CLOSE SYMMETRIC KEY SK_01;

REVERT 
GO

EXEC AS User = 'profe2';
GO

-- Ejecutado como profe2:
OPEN SYMMETRIC KEY SK_02 DECRYPTION BY CERTIFICATE profe2cert;
SELECT 
    DNI_cliente,
    CONVERT(VARCHAR, DecryptByKey(Dir_cliente)) AS Direccion,
    CONVERT(VARCHAR, DecryptByKey(Telf_cliente)) AS Telefono
FROM alumnos;
CLOSE SYMMETRIC KEY SK_02;

REVERT
GO
-- Otro ejemplo
-- Crear un sistema para registrar pagos de alumnos
-- los datos de la tarjeta de crédito se almacenen encriptados
-- Cada profesor solo podrá ver los pagos que registró

REVERT
GO
-- Creamos la tabla de pagos
CREATE TABLE [autoescuelaP].[dbo].[pagos] (
    [ID_pago] INT IDENTITY(1,1) PRIMARY KEY,
    [DNI_alumno] VARCHAR(9) NOT NULL,
    [Monto] DECIMAL(10,2) NOT NULL,
    [Fecha_pago] DATE NOT NULL,
    [Tarjeta_credito] VARBINARY(MAX),  
    [Titular_tarjeta] VARBINARY(MAX)   
);
GO

-- Otorgamos permisos
GRANT SELECT, INSERT ON [pagos] TO profe1, profe2;
GO

-- Creamos procedimiento almacenado para insertar pagos
DROP PROCEDURE SP_RegistrarPagoEncriptado;
GO

CREATE PROCEDURE SP_RegistrarPagoEncriptado
    @DNI_alumno VARCHAR(9),
    @Monto DECIMAL(10,2),
    @Fecha_pago DATE,
    @Tarjeta_credito VARCHAR(19),
    @Titular_tarjeta VARCHAR(100)
WITH EXECUTE AS CALLER
AS
BEGIN
    DECLARE @ClaveSimetrica VARCHAR(10);

    -- Determinar la clave según el usuario
    SET @ClaveSimetrica = 
        CASE USER_NAME()
            WHEN 'profe1' THEN 'SK_01'
            WHEN 'profe2' THEN 'SK_02'
        END;

    -- Abrir solo la clave necesaria
    IF @ClaveSimetrica = 'SK_01'
    BEGIN
        OPEN SYMMETRIC KEY SK_01 DECRYPTION BY CERTIFICATE profe1cert;
    END
    ELSE IF @ClaveSimetrica = 'SK_02'
    BEGIN
        OPEN SYMMETRIC KEY SK_02 DECRYPTION BY CERTIFICATE profe2cert;
    END

    -- Insertar datos
    INSERT INTO [autoescuelaP].[dbo].[pagos] (
        [DNI_alumno],
        [Monto],
        [Fecha_pago],
        [Tarjeta_credito],
        [Titular_tarjeta]
    )
    VALUES (
        @DNI_alumno,
        @Monto,
        @Fecha_pago,
        EncryptByKey(Key_GUID(@ClaveSimetrica), @Tarjeta_credito),
        EncryptByKey(Key_GUID(@ClaveSimetrica), @Titular_tarjeta)
    );

    -- Cerrar la clave
    IF @ClaveSimetrica = 'SK_01'
    BEGIN
        CLOSE SYMMETRIC KEY SK_01;
    END
    ELSE IF @ClaveSimetrica = 'SK_02'
    BEGIN
        CLOSE SYMMETRIC KEY SK_02;
    END
END;
GO

GRANT EXECUTE ON [dbo].[SP_RegistrarPagoEncriptado] TO profe1, profe2;
GO

REVERT
GO
-- Insertamos
EXEC AS USER = 'profe1';
GO

EXEC SP_RegistrarPagoEncriptado
    @DNI_alumno = '12345678A',
    @Monto = 250.50,
    @Fecha_pago = '2025-03-20',
    @Tarjeta_credito = '4111-1111-1111-1111',
    @Titular_tarjeta = 'Carlos García López';
GO

REVERT;
GO

EXEC AS USER = 'profe2';
GO

EXEC SP_RegistrarPagoEncriptado
    @DNI_alumno = '55443322L',
    @Monto = 300.00,
    @Fecha_pago = '2025-03-21',
    @Tarjeta_credito = '5500-0000-0000-0004',
    @Titular_tarjeta = 'Ana Ruiz Gómez';
GO

REVERT;
GO

SELECT * FROM pagos;
GO

EXEC AS USER = 'profe1';
OPEN SYMMETRIC KEY SK_01 DECRYPTION BY CERTIFICATE profe1cert;

SELECT 
    CONVERT(VARCHAR, DecryptByKey(Tarjeta_credito)) AS Tarjeta,
    CONVERT(VARCHAR, DecryptByKey(Titular_tarjeta)) AS Titular
FROM pagos;

CLOSE SYMMETRIC KEY SK_01;
REVERT;
GO

EXEC AS USER = 'profe2';
OPEN SYMMETRIC KEY SK_02 DECRYPTION BY CERTIFICATE profe2cert;

SELECT 
    CONVERT(VARCHAR, DecryptByKey(Tarjeta_credito)) AS Tarjeta,
    CONVERT(VARCHAR, DecryptByKey(Titular_tarjeta)) AS Titular
FROM pagos;

CLOSE SYMMETRIC KEY SK_02;


REVERT
GO


-- Encriptar con frase
SELECT * FROM profesor;
GO
-- Declaramos una variable y almacenamos la frase
DECLARE @FraseSecreta VARCHAR(100) = 'Voy aprobar bases de datos';

-- añadimos datos usando la frase
UPDATE [profesor]
    SET profesor_Dir_profe = EncryptByPassPhrase(@FraseSecreta, 'Calle Gran Vía 78, Madrid')
    WHERE profesor_DNI_profe = '09876543Q';

UPDATE [autoescuelaP].[dbo].[profesor]
    SET profesor_Dir_profe = EncryptByPassPhrase(@FraseSecreta, 'Avenida Diagonal 123, Barcelona')
    WHERE profesor_DNI_profe = '10987654R';

SELECT * FROM profesor;
GO

-- Comprobamos desencriptación
DECLARE @FraseSecreta VARCHAR(100) = 'Voy aprobar bases de datos';

SELECT 
    profesor_DNI_profe AS 'DNI del profesor',
    CONVERT(VARCHAR(100), 
        DecryptByPassPhrase(@FraseSecreta, profesor_Dir_profe)
    ) AS DireccionDescifrada
FROM [profesor]
WHERE profesor_DNI_profe IN ('09876543Q', '10987654R');


-- Encriptar Backup

USE MASTER;
GO
-- Creamos master key
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'Abcd1234.';
GO

-- Creamos certificado
CREATE CERTIFICATE [CertificadoBackup]
WITH SUBJECT = 'Certificado encriptar backups';
GO

-- Crear backup del certificado (por si se pierde)
BACKUP CERTIFICATE [CertificadoBackup]
	TO FILE = 'C:\Backup\Certificados\CertificadoBackup.cert'
	WITH PRIVATE KEY (
						FILE = 'C:\Backup\Certificados\KeyBackup.key',
						ENCRYPTION BY PASSWORD = 'Abcd1234.'
					 );
GO

-- Realizamos bacup encriptado
BACKUP DATABASE [AutoescuelaP]
	TO DISK = 'C:\Backup\AutoescuelaP.bak'
	WITH COMPRESSION, ENCRYPTION(ALGORITHM = AES_256,
	SERVER CERTIFICATE = [CertificadoBackup]);
GO

-- IMPORTANTE: El usuario que ejecute el restore debe tener permiso cobre el certificado y sobre la clave
-- GRANT VIEW DEFINITION ON CERTIFICATE::CertificadoBackup TO usuario
-- GO
-- GRANT VIEW DEFINITION ON SYMMETRIC KEY::KeyoBackup TO usuario
-- GO

RESTORE DATABASE [AutoescuelaP]
FROM DISK = 'C:\Backup\AutoescuelaP.bak'
WITH REPLACE
GO

-- Encriptación TDE

-- Creamos master key:
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'Abcd1234.';
GO

-- Creamos certificado:
CREATE CERTIFICATE [CertificadoTDE]
WITH SUBJECT = 'Certificado encriptar TDE';
GO

SELECT TOP 1 *
FROM sys.certificates ORDER BY name DESC
GO

-- Hacemos backup del certificado
BACKUP CERTIFICATE [CertificadoTDE]
	TO FILE = 'C:\Backup\Certificados\CertificadoTDE.cert'
	WITH PRIVATE KEY (
						FILE = 'C:\Backup\Certificados\KeyTDE.key',
						ENCRYPTION BY PASSWORD = 'Abcd1234.'
					 );
GO

USE autoescuelaP;
GO

-- Creamos el código de encriptación
CREATE DATABASE ENCRYPTION KEY
	WITH ALGORITHM = AES_256
	ENCRYPTION BY SERVER CERTIFICATE CertificadoTDE;
GO

-- Lo activamos
ALTER DATABASE [AutoescuelaP] SET ENCRYPTION ON;
GO

SELECT DB_name(database_id) AS 'Database', encryption_state
FROM sys.dm_database_encryption_keys;
GO

-- Hacemos bakcup completo
BACKUP DATABASE AutoescuelaP
TO DISK = 'C:\Backup\RecoveryfullWithTDE.bak';
GO

-- Hacemos backup de log
BACKUP LOG AutoescuelaP
TO DISK = 'C:\Backup\RecoveryWithTDE_log.bak';
GO


USE master;
ALTER DATABASE AutoescuelaP SET SINGLE_USER WITH ROLLBACK IMMEDIATE;  
EXEC sp_detach_db 'AutoescuelaP';
GO

USE master;
CREATE DATABASE AutoescuelaP  
ON (FILENAME = 'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\AutoescuelaP.mdf'),  
   (FILENAME = 'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\AutoescuelaP_log.ldf')  
FOR ATTACH;
GO


-- HASHING
-- Vamos a aplicar hashing con salting a la tabla nómina
-- De esta forma cuando se añada una nómina nueva, se aplicará el hash al nº de cuenta 

ALTER TABLE [dbo].[Nomina]
ALTER COLUMN [N_Cuenta] VARCHAR(100) NULL;

CREATE OR ALTER TRIGGER insertar_nomina_hash
ON Nomina
INSTEAD OF INSERT
AS
DECLARE
	@salt VARCHAR(16),@hash VARCHAR(64),
	@cuenta VARCHAR(80),@hashedcuenta VARCHAR(80),
	@Id_Nomina VARCHAR(12),@Department VARCHAR(12),  
    @Nivel VARCHAR(12),@H_extra VARCHAR(12),  
    @contrato_ID_contrato INT;  
	SELECT @Id_Nomina = ins.Id_Nomina,  
		   @Department = ins.Department,  
           @Nivel = ins.Nivel,  
           @H_extra = ins.H_extra,  
           @cuenta = ins.N_Cuenta,  
           @contrato_ID_contrato = ins.contrato_ID_contrato  
	FROM INSERTED ins;
BEGIN
	SET @cuenta = (SELECT N_Cuenta FROM inserted) -- capturo el dato a insertar
	SELECT @salt = CONVERT(VARCHAR(16), CRYPT_GEN_RANDOM(8),2) -- calculo un salt para reforzar el hash
	SET @hash = CONVERT(VARCHAR(64),HashBytes('SHA2_256', (@salt + @cuenta)),2) -- Obtengo el hash
	SET @hashedcuenta = @salt + @hash; -- aplico el salt al hash
	INSERT INTO Nomina ([Id_Nomina], [Department], [Nivel], [H_extra], [N_Cuenta], [contrato_ID_contrato])
	VALUES (@Id_Nomina, @Department, @Nivel, @H_extra, @hashedcuenta, @contrato_ID_contrato);  -- inserto el valor encriptado
END;
GO


-- Compruebo
INSERT INTO [dbo].[Nomina] 
    ([Id_Nomina], [Department], [Nivel], [H_extra], [N_Cuenta], [contrato_ID_contrato])  
VALUES  
    ('NOM014', 'IT', 'Senior', '5', 'ES1234567890123456789012', 3);  
GO

SELECT * FROM Nomina;
GO

-- Función para comprobar cuenta correcta
CREATE OR ALTER FUNCTION cuentavalida (
        @Id_Nomina varchar(20),@nuevacuenta varchar(30) 
)
RETURNS  bit            
AS

BEGIN
    DECLARE 
        @isValid bit,@cuentalmacenada varchar(80),@nuevacuentahash varchar(80), 
        @salt varchar(16),@hash varchar(64) 
    SET @cuentalmacenada = (SELECT [N_Cuenta] 
								FROM Nomina 
								WHERE Id_Nomina = @Id_Nomina)
	IF (@cuentalmacenada IS NULL) RETURN 0
        SET @salt = SUBSTRING(@cuentalmacenada, 1, 16)
        SET @hash = CONVERT(VARCHAR(64),HashBytes('SHA2_256', (@salt + @nuevacuenta)),2)
        SET @nuevacuentahash = @salt + @hash;

        IF (@cuentalmacenada != @nuevacuentahash) 
            SET @isValid = 0 
        ELSE
            SET @isValid = 1 
        RETURN @isValid

END;
GO

-- Comprobamos
SELECT dbo.cuentavalida('NOM014', 'ES1234567890123456789012') AS EsValida;
GO

SELECT dbo.cuentavalida('NOM014', 'ES5555567890123456785555') AS EsValida;
GO



-- Opción B (modificación realizada al no funcionarme la anterior, también válida)
CREATE OR ALTER FUNCTION cuentavalida2 (
        @Id_Nomina varchar(12),
		@nuevacuenta varchar(100) 
)
RETURNS  INT
AS
BEGIN
    DECLARE 
        @isValid INT,
		@cuentalmacenada varchar(100),
		@nuevacuentahash varchar(100), 
        @salt varchar(16),
		@hash varchar(64)
		
   -- Recupero la Password
    SELECT @cuentalmacenada = [N_Cuenta] 
		FROM Nomina 
		WHERE Id_Nomina = @Id_Nomina

    -- Password incorrecta
	IF (@cuentalmacenada IS NULL)
        RETURN 3;

	SET @salt = SUBSTRING(@cuentalmacenada, 1, 16);
    
    -- Calcular hash con el salt + nueva cuenta
    SET @hash = CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', @salt + @nuevacuenta), 2);
    
    -- Construir hash completo (salt + hash)
    SET @nuevacuentahash = @salt + @hash;

    -- Comparar con el valor almacenado
    IF (@cuentalmacenada != @nuevacuentahash)
        SET @isValid = 0;  -- No coincide
    ELSE
        SET @isValid = 1;      -- Coincide

    RETURN @isValid;
END;
GO

-- Comprobamos
SELECT dbo.cuentavalida2('NOM014', 'ES1234567890123456789012') AS EsValida;
GO


-- DDM Dynamic Data Masking

-- Creamos la tabla con las máscaras
DROP TABLE IF EXISTS aprobados
GO
CREATE TABLE aprobados(
	ID INT IDENTITY PRIMARY KEY,
	Nombre NVARCHAR(15) MASKED WITH (FUNCTION = 'default()') NULL,
	Apellidos NVARCHAR(30) MASKED WITH (FUNCTION = 'default()') NULL,
	Email NVARCHAR(18) MASKED WITH (FUNCTION = 'email()') NULL,
	N_cuenta NVARCHAR (25) MASKED WITH (FUNCTION = 'partial(0,"XXXX-XXXX-XXXX-",4)') NULL
);
GO

-- Insertamos una prueba

INSERT INTO aprobados (Nombre, Apellidos, Email, N_Cuenta)
VALUES ('Borja', 'Costa Rojo', 'cjgalego@gmail.com', '2100-2938-7765-9876-2345');
GO

SELECT * FROM aprobados;
GO

GRANT SELECT ON aprobados TO profe1;
GO

EXECUTE AS USER = 'profe1';
SELECT * FROM aprobados;
GO

REVERT
GO

-- Probamos a dar permiso UNMASK al usuario profe1
GRANT UNMASK ON aprobados TO profe1;
GO
--Comprobamos
EXECUTE AS USER = 'profe1';
SELECT * FROM aprobados;
GO

-- Vamos a dar permiso de consultar a profe2
-- Tmbién vamos a desenmascarar el campo Email

GRANT SELECT ON aprobados TO profe2;
GO

ALTER TABLE aprobados
	ALTER COLUMN email DROP MASKED;
GO

EXECUTE AS USER = 'profe2';
GO
SELECT * FROM aprobados;
GO

REVERT 
GO
-- SECUENCIAS
-- Usar dos secuencias para distribuir los alumnos que se matriculen en aulas de 5 alumnos
-- Vamos a suponer que disponemos de 3 aulas, cuando se llenen se reinicia con el aula 1

-- Añadimos la columna aula a la tabla clientes
ALTER TABLE dbo.clientes ADD aula INT;
GO
-- Creamos una secuencia que se reinicie cada 15 (5 alumnos × 3 aulas)
CREATE SEQUENCE dbo.ControlAulas
START WITH 1
INCREMENT BY 1
MINVALUE 1
MAXVALUE 15
CYCLE;

-- Actualizamos el aula automáticamente usando un valor calculado
ALTER TABLE dbo.clientes
ADD CONSTRAINT DF_Aula DEFAULT 
((NEXT VALUE FOR dbo.ControlAulas - 1)/5 % 3 + 1) FOR aula;
GO

-- Comprobamos


INSERT INTO clientes (DNI_cliente, N_cliente, Apel1_cliente, Apel2_cliente, Dir_cliente, Email_cliente, Telf_cliente, localidad_cod_localidad)
VALUES
('52418567H', 'Ana', 'González', 'Pérez', 'Calle Real 45', 'ana.gonzalez@coruna.es', '681234567', 1),
('36259874L', 'Carlos', 'Martínez', NULL, 'Avenida de la Marina 12', 'carlos.martinez@coruna.es', '689876543', 1),
('15487236M', 'Laura', 'Díaz', 'Fernández', 'Rúa de la Torre 3', 'laura.diaz@coruna.es', '666112233', 1),
('78965412T', 'Pablo', 'López', 'Gómez', 'Callejón del Sol 7', 'pablo.lopez@coruna.es', '677445566', 1),
('45879632R', 'Sofía', 'Rodríguez', NULL, 'Plaza de María Pita 9', 'sofia.rodriguez@coruna.es', '655998877', 1),
('32659874W', 'David', 'Sánchez', 'Castro', 'Calle de San Andrés 22', 'david.sanchez@coruna.es', '699332211', 1),
('11223344A', 'Elena', 'Fernández', 'Vázquez', 'Avenida de Finisterre 100', 'elena.fernandez@coruna.es', '688776655', 1),
('99887766B', 'Javier', 'Romero', NULL, 'Rúa Panaderas 15', 'javier.romero@coruna.es', '612345678', 1),
('66554433C', 'Lucía', 'García', 'Iglesias', 'Calle de la Estrella 4', 'lucia.garcia@coruna.es', '687654321', 1),
('22334455D', 'Pedro', 'Torres', 'Molina', 'Praza de Pontevedra 1', 'pedro.torres@coruna.es', '600112233', 1),
('77889900E', 'Marta', 'Navarro', 'Ortega', 'Calle de San Juan 30', 'marta.navarro@coruna.es', '699887766', 1),
('44556677F', 'Daniel', 'Herrera', NULL, 'Avenida de Oza 250', 'daniel.herrera@coruna.es', '633445566', 1),
('33445566G', 'Paula', 'Domínguez', 'Castro', 'Rúa de la Franja 8', 'paula.dominguez@coruna.es', '677889900', 1),
('12345678Z', 'Adrián', 'Vázquez', 'Lorenzo', 'Calle de la Barrera 12', 'adrian.vazquez@coruna.es', '688990011', 1),
('87654321X', 'Raquel', 'Castro', 'Santos', 'Avenida de los Cantones 5', 'raquel.castro@coruna.es', '622334455', 1),
('19283746S', 'Sergio', 'Ortega', 'Díaz', 'Rúa de la Galera 17', 'sergio.ortega@coruna.es', '655443322', 1),
('56473829V', 'Carmen', 'Molina', NULL, 'Calle de la Torre 55', 'carmen.molina@coruna.es', '699554433', 1),
('65748392N', 'Alejandro', 'Iglesias', 'Gómez', 'Praza de España 2', 'alejandro.iglesias@coruna.es', '611223344', 1),
('93847562P', 'Nuria', 'Ramírez', 'Fernández', 'Calle de la Oliva 9', 'nuria.ramirez@coruna.es', '633778899', 1),
('47586920Q', 'Hugo', 'Pérez', 'López', 'Avenida de Alfonso Molina 33', 'hugo.perez@coruna.es', '688009911', 1);
GO

SELECT * FROM clientes;
GO

-- ROW LEVEL SECURITY
-- Vamos a usar el Row Level Security para hacer que cada profesor 
-- solo pueda acceder a sus alumnos en la tabla practica

-- Creamos la función de seguridad
CREATE OR ALTER FUNCTION dbo.fn_seguridad_profesor(@DNI_profe AS SYSNAME)
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN (
    SELECT 1 AS acceso
    WHERE @DNI_profe = USER_NAME()
    OR IS_ROLEMEMBER('db_owner') = 1
);
GO  -- Necesario para separar lotes

-- Paso 2: Crear la política de seguridad
CREATE SECURITY POLICY PoliticaSeguridadPractica
ADD FILTER PREDICATE dbo.fn_seguridad_profesor(profe_practicas_profesor_DNI_profe) 
ON dbo.practica
WITH (STATE = ON);
GO

/*
    DROP SECURITY POLICY PoliticaSeguridadPractica;
    DROP FUNCTION dbo.fn_seguridad_profesor;
GO
*/

-- Comprobamos
-- Creamos usuario de profesor
CREATE USER [09876543Q] WITHOUT LOGIN;
GRANT SELECT ON dbo.practica TO [09876543Q];
GO

-- Test acceso profesor
EXECUTE AS USER = '09876543Q';
SELECT * FROM practica;  -- Solo verá 4 registros (los de este profesor)
REVERT;

SELECT * FROM practica;
GO

-- Otro ejemplo

-- Crear tabla trabajadores
CREATE TABLE trabajadores (
    id INT IDENTITY(1,1) PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    apellidos VARCHAR(100) NOT NULL,
    telefono VARCHAR(15) NOT NULL,
    sueldo DECIMAL(10,2) NOT NULL,
    puesto VARCHAR(50) NOT NULL,
    departamento VARCHAR(50) CHECK (departamento IN ('Recursos humanos', 'Logística', 'Administración')));
GO

-- Insertar datos de ejemplo
INSERT INTO trabajadores (nombre, apellidos, telefono, sueldo, puesto, departamento) VALUES
('Marta', 'González López', '681234567', 2450.00, 'Analista de RRHH', 'Recursos humanos'),
('Carlos', 'Martínez Silva', '689876543', 2750.00, 'Reclutador técnico', 'Recursos humanos'),
('Ana', 'Díaz Fernández', '666112233', 2950.00, 'Jefa de personal', 'Recursos humanos'),
('Luis', 'Pérez Ríos', '677445566', 2100.00, 'Coordinador de almacén', 'Logística'),
('Sofía', 'Rodríguez Míguez', '655998877', 1950.00, 'Operario logístico', 'Logística'),
('Diego', 'Santos Neira', '699332211', 2300.00, 'Jefe de transporte', 'Logística'),
('Paula', 'Vázquez Castro', '688776655', 2250.00, 'Contable senior', 'Administración'),
('Jorge', 'López Blanco', '612345678', 1850.00, 'Auxiliar administrativo', 'Administración'),
('Lucía', 'Castro Ferreiro', '687654321', 2550.00, 'Directora financiera', 'Administración'),
('Iria', 'Méndez Sande', '600112233', 2650.00, 'Especialista en nóminas', 'Recursos humanos'),
('Brais', 'Núñez Vilas', '699887766', 2150.00, 'Operario de carga', 'Logística'),
('Nerea', 'Iglesias Boo', '633445566', 2400.00, 'Analista de inventarios', 'Logística'),
('Hugo', 'Romero Cambre', '677889900', 1950.00, 'Asistente contable', 'Administración'),
('Carla', 'Mosquera Pardo', '688990011', 2850.00, 'Responsable de formación', 'Recursos humanos'),
('David', 'Bermúdez Leis', '622334455', 2050.00, 'Gestor de almacén', 'Logística');
GO

SELECT * FROM trabajadores;
GO


ALTER TABLE trabajadores
ADD usuario VARCHAR(50);
GO

CREATE FUNCTION dbo.fn_FiltroPorDepartamento(@departamento VARCHAR(50))
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN (
    SELECT 1 AS acceso
    FROM dbo.trabajadores
    WHERE departamento = @departamento AND usuario = USER_NAME()
);
GO

CREATE SECURITY POLICY Trabajadores_Policy
ADD FILTER PREDICATE dbo.fn_FiltroPorDepartamento(departamento) ON dbo.trabajadores,
ADD BLOCK PREDICATE dbo.fn_FiltroPorDepartamento(departamento) ON dbo.trabajadores
WITH (STATE = ON);
GO


/*
DROP SECURITY POLICY Trabajadores_Policy;
GO
DROP FUNCTION dbo.fn_FiltroTrabajadores;
GO
*/

-- usuario de recursos humanos
CREATE USER mgonzalez WITHOUT LOGIN;
GO
GRANT SELECT, INSERT, UPDATE ON dbo.trabajadores TO mgonzalez;
GO

-- usuario de logística
CREATE USER dsantos WITHOUT LOGIN;
GO
GRANT SELECT, INSERT, UPDATE ON dbo.trabajadores TO dsantos;
GO

EXECUTE AS USER = 'mgonzalez';
GO

SELECT * FROM trabajadores;
GO

INSERT INTO trabajadores (nombre, apellidos, telefono, sueldo, puesto, departamento, usuario)
VALUES ('Juan', 'Pérez García', '600123456', 2500.00, 'Analista', 'Logística', 'jperez');
GO

INSERT INTO trabajadores (nombre, apellidos, telefono, sueldo, puesto, departamento, usuario)
VALUES ('Juan', 'Pérez García', '600123456', 2500.00, 'Analista', 'Recursos humanos', 'jperez');
GO


REVERT
GO

EXECUTE AS USER = 'dsantos';

INSERT INTO trabajadores (nombre, apellidos, telefono, sueldo, puesto, departamento, usuario)
VALUES ('Juan', 'Pérez García', '600123456', 2500.00, 'Analista', 'Logística', 'jperez');
GO

INSERT INTO trabajadores (nombre, apellidos, telefono, sueldo, puesto, departamento, usuario)
VALUES ('Juan', 'Pérez García', '600123456', 2500.00, 'Analista', 'Recursos humanos', 'jperez');
GO














-- Auditorías
PRINT USER
GO

USE MASTER 
GO

-- Auditorías de servidor

CREATE SERVER AUDIT [App_Auditoria_marzo2025]
	TO application_log
WITH
(queue_delay = 1000,
 on_failure = fail_operation
 )
 GO


 CREATE SERVER AUDIT [Security_Auditoria_marzo2025]
	TO security_log
WITH
(queue_delay = 1000,
 on_failure = fail_operation
 )
 GO

 -- Creamos carpeta para guardar la auditoría
 EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;

EXEC sp_configure 'xp_cmdshell', 1;
RECONFIGURE;

EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;

EXEC xp_cmdshell 'mkdir C:\auditorias';

-- Creamos auditoría a archivo
  CREATE SERVER AUDIT [File_Auditoria_marzo2025]
	TO FILE
(filepath = 'c:\auditorias\',
 maxsize = 0mb,
 max_rollover_files = 2147483647,
 reserve_disk_space = off
 )
 WITH(
	queue_delay = 5000,
	on_failure = continue
	)
GO
-- Activamos auditoría
ALTER SERVER AUDIT File_Auditoria_marzo2025 WITH (STATE = ON)
GO

-- Creamos especificaciones nivel servidor
-- Regitrará inicios de sesión fallidos, inicios de sesión exitosos y cambios de contraseña


CREATE SERVER AUDIT SPECIFICATION [Specificacions_Audit_File]
FOR SERVER AUDIT [File_Auditoria_marzo2025]
	ADD (FAILED_LOGIN_GROUP), 
	ADD (SUCCESSFUL_LOGIN_GROUP), 
	ADD (USER_CHANGE_PASSWORD_GROUP)  
GO

-- Comprobaciones
CREATE LOGIN UserTestAudit WITH PASSWORD = '123456';
CREATE USER UserTestAudit FOR LOGIN UserTestAudit;
GO

ALTER LOGIN UserTestAudit WITH PASSWORD = 'Abcd1234.';
GO


SELECT 
    event_time,
    action_id,
    succeeded,
    server_principal_name,
    statement,
    file_name
FROM sys.fn_get_audit_file('C:\auditorias\*', DEFAULT, DEFAULT);
GO


-- Auditoría de base de datos

CREATE DATABASE AUDIT SPECIFICATION [Auditoría_Autoescuela_2025]
FOR SERVER AUDIT [File_auditoria_marzo2025]
ADD (SELECT ON OBJECT::[trabajadores] BY [dbo]),
ADD (INSERT ON OBJECT::[trabajadores] BY [dbo]),
ADD (DELETE ON OBJECT::[trabajadores] BY [dbo])
GO

SELECT * FROM trabajadores;
GO

ALTER DATABASE AUDIT SPECIFICATION [Auditoría_Autoescuela_2025] WITH (STATE = ON);
GO


SELECT * FROM pagos;
GO

CREATE TABLE [dbo].[pagos](
	[ID_pago] [int] IDENTITY(1,1) NOT NULL,
	[DNI_alumno] [varchar](9) NOT NULL,
	[Monto] [decimal](10, 2) NOT NULL,
	[Fecha_pago] [date] NOT NULL,
	[Tarjeta_credito] [varchar](25) NOT NULL,
	[Titular_tarjeta] [varchar](60) NOT NULL)
WITH
(
	SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.PagosHistory),
	LEDGER = ON
);
	GO

INSERT INTO [dbo].[pagos] ([DNI_alumno], [Monto], [Fecha_pago], [Tarjeta_credito], [Titular_tarjeta])
VALUES 
('12345678A', 50.00, '2024-01-10', '4111 1111 1111 1111', 'Juan Pérez'),
('23456789B', 75.50, '2024-01-15', '5500 0000 0000 0004', 'María López'),
('34567890C', 120.00, '2024-01-20', '3400 0000 0000 0009', 'Carlos Sánchez'),
('45678901D', 89.99, '2024-01-25', '3023 0000 0000 0004', 'Laura García'),
('56789012E', 35.25, '2024-02-05', '6011 0000 0000 0004', 'Andrés Fernández'),
('67890123F', 99.99, '2024-02-10', '3530 1113 3330 0000', 'Paula Gómez'),
('78901234G', 200.00, '2024-02-15', '6304 0000 0000 0000', 'David Martínez'),
('89012345H', 45.75, '2024-02-20', '4111 1111 1111 1111', 'Sofía Ramírez'),
('90123456I', 150.00, '2024-02-25', '5500 0000 0000 0004', 'Luis Ortega'),
('01234567J', 80.00, '2024-03-01', '3405 0000 0000 0009', 'Elena Herrera'),
('11111111K', 60.50, '2024-03-05', '3000 0000 0000 0674', 'Fernando Ruiz'),
('22222222L', 110.25, '2024-03-10', '6011 0000 0000 0004', 'Ana Domínguez'),
('33333333M', 95.00, '2024-03-15', '3530 1113 3330 0000', 'Pedro Salazar'),
('44444444N', 130.75, '2024-03-20', '6304 0000 0000 0000', 'Clara Mendoza'),
('55555555O', 175.00, '2024-03-25', '4111 1111 1111 1111', 'Hugo Morales'),
('66666666P', 220.99, '2024-04-01', '5500 0000 0000 0004', 'Marta Gil'),
('77777777Q', 48.75, '2024-04-05', '3400 0000 0000 4009', 'Sergio Castro'),
('88888888R', 90.25, '2024-04-10', '3055 0000 0000 0004', 'Isabel Vega'),
('99999999S', 125.00, '2024-04-15', '6011 0000 0000 0004', 'Javier Núñez'),
('00000000T', 55.50, '2024-04-20', '3530 1113 3330 0000', 'Beatriz Torres');
GO

SELECT * FROM pagos;
GO


SELECT [ledger_start_transaction_id],
		[ledger_end_transaction_id],
		[ledger_start_sequence_number],
		[ledger_end_sequence_number]
	FROM pagos
GO


SELECT * FROM sys.database_ledger_transactions
GO

SELECT * FROM sys.database_ledger_blocks
GO

INSERT INTO [dbo].[pagos] ([DNI_alumno], [Monto], [Fecha_pago], [Tarjeta_credito], [Titular_tarjeta])
VALUES 
('12345678Z', 60.00, '2024-01-15', '5555 5555 1111 1111', 'Juana Mayol');
GO

UPDATE pagos
	SET Tarjeta_credito = '5555 5555 1111 5555'
	WHERE DNI_alumno = '12345678Z'
GO

DELETE pagos
	WHERE DNI_alumno = '12345678Z';
GO

DELETE pagos
	WHERE DNI_alumno = '23456789B';
GO

SELECT [ledger_start_transaction_id],
		[ledger_end_transaction_id],
		[ledger_start_sequence_number],
		[ledger_end_sequence_number]
	FROM pagos
GO


CREATE TABLE [dbo].[examen](
	[ID_examen] [int] NOT NULL,
	[F_examen] [date] NULL,
	[Tipo_examen] [nvarchar](10) NULL,
	[Tipo_carnet] [nvarchar](10) NULL,
	[cliente_DNI_cliente] [varchar](9) NOT NULL,
	[vehiculo_vehiculo_ID] [numeric](28, 0) NOT NULL)
WITH
	(LEDGER = ON (APPEND_ONLY = ON));
GO


-- Insertar un registro en la tabla examen
INSERT INTO [dbo].[examen] 
([ID_examen], [F_examen], [Tipo_examen], [Tipo_carnet], [cliente_DNI_cliente], [vehiculo_vehiculo_ID])
VALUES 
(1, '2025-03-21', 'Teórico', 'B', '12345678A', 1001);
GO

-- Eliminar un registro de la tabla examen
DELETE FROM [dbo].[examen] 
WHERE ID_examen = 1;
GO


-- Actualizar un registro en la tabla examen
UPDATE [dbo].[examen]  
SET 
    F_examen = '2025-04-01', 
    Tipo_examen = 'Práctico', 
    Tipo_carnet = 'A2'
WHERE ID_examen = 1;
GO


SELECT [ledger_start_transaction_id],
		[ledger_start_sequence_number]
	FROM examen
GO


-- Prueba de detección de modificaciones

-- Consultamos el historial de bloques
SELECT * FROM sys.database_ledger_blocks
go

-- Generamos el Ledger Digest
EXECUTE sp_generate_database_ledger_digest
go

-- Activamos Snapshot isolation
USE MASTER
GO
ALTER DATABASE AutoescuelaP
	SET ALLOW_SNAPSHOT_ISOLATION ON;
GO

USE AutoescuelaP
GO

-- Comprobamos integridad (da error por tipo de dato)
EXECUTE sp_verify_database_ledger  
@digests = N'[{"database_name":"AutoescuelaP","block_id":0,"hash":"0xCE4736A4A458A617ACADE243D1BF35539A32FA8853A62F5F3CEC62FCA4A9089A","last_transaction_commit_time":"2025-03-21T01:32:13.8433333","digest_time":"2025-03-21T12:25:27.7360992"}]',  
@table_name ='pagos'  
GO  

-- Comprobación válida
EXECUTE sp_verify_database_ledger N'
[{"database_name":"AutoescuelaP","block_id":0,"hash":"0xCE4736A4A458A617ACADE243D1BF35539A32FA8853A62F5F3CEC62FCA4A9089A","last_transaction_commit_time":"2025-03-21T01:32:13.8433333","digest_time":"2025-03-21T12:25:27.7360992"}
]';
GO  

-- Consultamos la posición que tiene cada dato
SELECT sys.fn_PhysLocFormatter(%%physloc%%) as [Physical RID], * 
FROM dbo.pagos
go

-- Consultamos la posición de un dato en concreto
SELECT sys.fn_PhysLocFormatter(%%physloc%%) as [Physical RID], * 
FROM dbo.pagos 
WHERE ID_pago = 5;
GO


-- Consultamos la página donde está el dato grabado
DBCC TRACEON(3604)
GO
DBCC PAGE(AutoescuelaP, 1, 1264, 3) -- Muestra la estructura de la página 2500
GO

-- Convertimos a VARBINARY
SELECT CONVERT (VARBINARY(33),'6011 0000 0000 0004') -- Conversión de tarjeta buena
GO
-- 0x36303131203030303020303030302030303034


SELECT CONVERT (VARBINARY(33),'6666 6666 6666 6666') -- Conversión de tarjeta pirateada
GO
-- 0x36363636203636363620363636362036363636


-- Cambiar los registros de la página

-- Desactivamos la verificación de páginas
ALTER DATABASE AutoescuelaP SET PAGE_VERIFY NONE
GO

-- Cambiamos la base de datos a monousuario
ALTER DATABASE AutoescuelaP SET SINGLE_USER
GO

-- Reescribimos la página
--DBCC WRITEPAGE ('AutoescuelaP', 1, 1344, 104, 19, 0x36363636203636363620363636362036363636)
--GO

DBCC WRITEPAGE (
    'AutoescuelaP',1,1264,640,19,0x36363636203636363620363636362036363636);
GO

-- Volvemos a poner la BD multiusuario y activamos control de página
ALTER DATABASE AutoescuelaP SET MULTI_USER
GO

ALTER DATABASE AutoescuelaP SET PAGE_VERIFY CHECKSUM
GO

-- Consultamos la tabla
SELECT * FROM pagos
GO

DBCC CHECKDB
GO

EXECUTE sp_verify_database_ledger N'
[{"database_name":"AutoescuelaP","block_id":0,"hash":"0xCE4736A4A458A617ACADE243D1BF35539A32FA8853A62F5F3CEC62FCA4A9089A","last_transaction_commit_time":"2025-03-21T01:32:13.8433333","digest_time":"2025-03-21T12:25:27.7360992"}
]';
GO  