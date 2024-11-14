
## DBATOOLS

#Instalae modulo dbatools desde galeria PowerShell 

Install-Module -Name dbatools 

# Comprobar que esta instalado el modulo dbatools

Get-Module dbatools -ListAvailable

#If the module is already installed, update it using the following commands: 

#For PowerShell 5.0 or later 

Update-Module -Name dbatools 


# Testa conectividad a una Instancia 

Test-DbaConnection localhost 

<#
ComputerName         : DESKTOP-V9719B2
InstanceName         : MSSQLSERVER
SqlInstance          : localhost
SqlVersion           : 15.0.2000
ConnectingAsUser     : DESKTOP-V9719B2\ccm
ConnectSuccess       : True
AuthType             : Windows Authentication
AuthScheme           : NTLM
TcpPort              : 1433
IPAddress            : 10.0.2.15
NetBiosName          : DESKTOP-V9719B2
IsPingable           : True
PSRemotingAccessible : True
DomainName           : WORKGROUP
LocalWindows         : 10.0.19045.0
LocalPowerShell      : 5.1.19041.3031
LocalCLR             : 4.0.30319.42000
LocalSMOVersion      : 16.200.0.0
LocalDomainUser      : False
LocalRunAsAdmin      : True
LocalEdition         : Desktop

#>
 

# testar conectividad a una determinada BF

Get-DbaDatabase -SqlInstance localhost -Database Pubs 

<#
ComputerName       : DESKTOP-V9719B2
InstanceName       : MSSQLSERVER
SqlInstance        : DESKTOP-V9719B2
Name               : Pubs
Status             : Normal
IsAccessible       : True
RecoveryModel      : Full
LogReuseWaitStatus : Nothing
SizeMB             : 80
Compatibility      : Version150
Collation          : Modern_Spanish_CI_AS
Owner              : DESKTOP-V9719B2\ccm
Encrypted          : False
LastFullBackup     : 23/10/2023 17:26:22
LastDiffBackup     : 01/01/0001 0:00:00
LastLogBackup      : 01/01/0001 0:00:00


#>

<#
#>

# Crear BD Pruebadbatools con determinadas propiedades

# Declaración de variables

$SqlInstance = 'localhost'
$Name = 'Pruebadbatools'
$DataFilePath = 'C:\data\' # Ruta del archivo de datos
$LogFilePath = 'C:\data\' # Ruta del archivo log
$Recoverymodel = 'Simple'
$Owner = 'sa'
$PrimaryFilesize = 1024
$PrimaryFileGrowth = 256
$LogSize = 512
$LogGrowth = 128

#Crear BD con cmdlet de dbatools New-DbaDatabase

New-DbaDatabase -SqlInstance $SqlInstance -Name $Name -DataFilePath $DataFilePath -LogFilePath $LogFilePath -Recoverymodel $Recoverymodel -Owner $Owner

# comprobar existencia
Get-DbaDatabase -SqlInstance $SqlInstance -Database $Name

# testar conectividad a una determinada BF

Get-DbaDatabase -SqlInstance localhost -Database pruebadbatools 

# Backup

# Creo directorio

New-Item "C:\tempdbatools" -ItemType Directory

ls c:\t*

Backup-DbaDatabase -SqlInstance localhost -Path C:\tempdbatools -Database pruebadbatools -Type Full

<#
SqlInstance     Database       Type TotalSize DeviceType Start                   Duration End                    
-----------     --------       ---- --------- ---------- -----                   -------- ---                    
DESKTOP-V9719B2 Pruebadbatools Full 2,95 MB   Disk       2023-11-14 16:28:15.000 00:00:00 2023-11-14 16:28:15.000

#>

cd C:\tempdbatools
ls 

<#
    Directorio: C:\tempdbatools


Mode                 LastWriteTime         Length Name                                                                                                                               
----                 -------------         ------ ----                                                                                                                               
-a----        14/11/2023     16:28        3103232 Pruebadbatools_202311141628.bak 

#>

# Borrar BD
Remove-DbaDatabase -SqlInstance localhost -Database pruebadbatools

<#
ComputerName : DESKTOP-V9719B2
InstanceName : MSSQLSERVER
SqlInstance  : DESKTOP-V9719B2
Database     : Pruebadbatools
Status       : Dropped

#>

# testar conectividad a una determinada BF

Get-DbaDatabase -SqlInstance localhost -Database pruebadbatools 

# No devuelve nada

# Restaurar
# Restore-DbaDatabase
# Documentación
# https://docs.dbatools.io/Restore-DbaDatabase.html

Restore-DbaDatabase -SqlInstance localhost -Path c:\tempdbatools –DatabaseName “probandodbatools” –ReplaceDbNameInFile -WithReplace

<#
ComputerName         : DESKTOP-V9719B2
InstanceName         : MSSQLSERVER
SqlInstance          : DESKTOP-V9719B2
BackupFile           : c:\tempdbatools\Pruebadbatools_202311141628.bak
BackupFilesCount     : 1
BackupSize           : 2,95 MB
CompressedBackupSize : 2,95 MB
Database             : probandodbatools
Owner                : DESKTOP-V9719B2\ccm
DatabaseRestoreTime  : 00:00:01
FileRestoreTime      : 00:00:01
NoRecovery           : False
RestoreComplete      : True
RestoredFile         : probandodbatools.mdf,probandodbatools_log.ldf
RestoredFilesCount   : 2
Script               : {RESTORE DATABASE [probandodbatools] FROM  DISK = N'c:\tempdbatools\Pruebadbatools_202311141628.bak' WITH  FILE = 1,  MOVE N'Pruebadbatools' TO N'C:\Program 
                       Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\probandodbatools.mdf',  MOVE N'Pruebadbatools_log' TO N'C:\Program Files\Microsoft SQL 
                       Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\probandodbatools_log.ldf',  NOUNLOAD,  REPLACE,  STATS = 10}
RestoreDirectory     : C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA
WithReplace          : True

#>

# testar conectividad a una determinada BF

Get-DbaDatabase -SqlInstance localhost -Database pruebadbatools 

# No devuelve nada

# testar conectividad a una determinada BF

Get-DbaDatabase -SqlInstance localhost -Database probandodbatools

<#


ComputerName       : DESKTOP-V9719B2
InstanceName       : MSSQLSERVER
SqlInstance        : DESKTOP-V9719B2
Name               : probandodbatools
Status             : Normal
IsAccessible       : True
RecoveryModel      : Simple
LogReuseWaitStatus : Nothing
SizeMB             : 16
Compatibility      : Version150
Collation          : Modern_Spanish_CI_AS
Owner              : DESKTOP-V9719B2\ccm
Encrypted          : False
LastFullBackup     : 01/01/0001 0:00:00
LastDiffBackup     : 01/01/0001 0:00:00
LastLogBackup      : 01/01/0001 0:00:00

#>

Restore-DbaDatabase -SqlInstance localhost -Path C:\tempdbatools -DestinationDataDirectory C:\data -WithReplace

<#

ComputerName         : DESKTOP-V9719B2
InstanceName         : MSSQLSERVER
SqlInstance          : DESKTOP-V9719B2
BackupFile           : C:\tempdbatools\Pruebadbatools_202311141628.bak
BackupFilesCount     : 1
BackupSize           : 2,95 MB
CompressedBackupSize : 2,95 MB
Database             : Pruebadbatools
Owner                : DESKTOP-V9719B2\ccm
DatabaseRestoreTime  : 00:00:01
FileRestoreTime      : 00:00:00
NoRecovery           : False
RestoreComplete      : True
RestoredFile         : Pruebadbatools.mdf,Pruebadbatools_log.ldf
RestoredFilesCount   : 2
Script               : {RESTORE DATABASE [Pruebadbatools] FROM  DISK = N'C:\tempdbatools\Pruebadbatools_202311141628.bak' WITH  FILE = 1,  MOVE N'Pruebadbatools' TO 
                       N'C:\data\Pruebadbatools.mdf',  MOVE N'Pruebadbatools_log' TO N'C:\data\Pruebadbatools_log.ldf',  NOUNLOAD,  REPLACE,  STATS = 10}
RestoreDirectory     : C:\data
WithReplace          : True
#>


# Compruebo desde SSMS