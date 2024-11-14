$PSVersionTable

$version=$PSVersionTable
$version


# instalando ultima versión

# PowerShell-7.3.8-win-x64.msi

#Comprobamos el valor de nuestra política
Get-ExecutionPolicy

Set-ExecutionPolicy Unrestricted

Get-ExecutionPolicy

Get-help

Get-help *SQL*

Get-Help Set-ExecutionPolicy –examples

Get-help -showWindow

ping localhost

ipconfig

# Para ver los Alias usamos el cmdlet
Get-alias
# Obtener Alias de un comdlet
Get-Alias -Definition "Get-Service"
# Obtener Alias de un comdlet
Get-Alias -Definition "Get-Service"
# Crear nuestro alias temporal
new-alias -Name d -Value get-childitem
# Comprobamos el alias creado
Get-Alias d
# Probando alias
d

# Para ver los procesos del sistema
Get-Process
# Reenvía a un archivo txt
Get-Process | out-file C:\procesos.txt
Notepad C:\procesos.txt
# Reenvía a un archivo .csv
Get-Process | export-Csv procs.csv
Notepad .\procs.csv
# Muestra en pantalla
Get-Process | Out-GridView


# SQL SERVER

Install-Module -Name SqlServer

Get-Module sqlserver

Get-Module SqlServer -ListAvailable

Install-Module -Name SqlServer -AllowClobber

Get-Module SqlServer -ListAvailable

Get-Service -Name *SQL*

Get-Command -Module SqlServer 

Get-Command -Module SqlServer -CommandType Cmdlet | Out-GridView 

Get-Command -Module SqlServer -CommandType Cmdlet



# Consultamoslos servicios del sistema y la salida es en ua ventana
Get-Service | Out-GridView

# Consultamoslos servicios del sistema que contienen sql(en formato tabla)
Get-Service | where-Object{$_.name -like '*sql*'} | Format-Table –AutoSize

# Consultamoslos servicios del sistema que contienen sql con salida Out-GridView
Get-Service | where-Object{$_.name -like '*sql*'} | Out-GridView

# Lo mismo pero con ALIAS ( ? = where-Object) y (ogv = Out-GridView)
Get-Service | ?{$_.name -like '*sql*'} | ogv

# Arrancar el servicio
Start-Service "SQLSERVERAGENT"

# Detener el servicio
Stop-Service "SQLSERVERAGENT"
# Control de flujo

# Consultamos los servicios
Get-Service | ?{$_.name -like '*sql*'} | ogv

# Arrancar el servicio
Start-Service "SQLSERVERAGENT"

# Consultamos los servicios
Get-Service | ?{$_.name -like '*sql*'} | ogv

# Control de flujo

# Consultamos los servicios
Get-service 

# Queremos los servicios que estan detenidos
# La ? es un alias para el cmdlet WHERE OBJECT y hace que entremos en una estructura repetitiva  {}
# $_ sustituye a Get-services
# Eq significa: igual a
Get-service | ?{$_.Status –eq “Stopped”}

# Comprobamos el status del servicio “Optimizar unidades ”
Get-service | ?{$_.Name –eq “defragsvc”}

# Iniciamos el servicio “Optimizar unidades ”
Get-service | ?{$_.Name –eq “defragsvc”} | %{$_.Start()}

# Comprobamos si esta iniciado el servicio “Optimizar unidades ”
Get-service | ?{$_.Name –eq “defragsvc”}

# Detenemos el servicio “Optimizar unidades ”
Get-service | ?{$_.Name –eq “defragsvc”} | %{$_.Stop()}

# Comprobamos si esta detenido el servicio “Optimizar unidades ”
Get-service | ?{$_.Name –eq “defragsvc”}

# SENTENCIAS T-SQL
# Invoke-Sqlcmd 

#############################

$SqlInstance = 'localhost'
$Name = 'Pubs'
Get-DbaDatabase -SqlInstance $SqlInstance -Database $Name

###################
help invoke-sqlcmd

Invoke-Sqlcmd -Query "SELECT GETDATE() AS TimeOfQuery" -ServerInstance "."

# TrustServerCertificate=True;

Invoke-Sqlcmd -Query "SELECT COUNT(*) AS Count FROM Authors" -ConnectionString "Data Source=.;Initial Catalog=Pubs;Integrated Security=True;ApplicationIntent=ReadOnly"
# ME DA ERROR 
# Invoke-Sqlcmd : A connection was successfully established with the server, but then an error occurred during the login process. (provider: SSL Provider, error: 0 - La cadena de 
# certificación fue emitida por una entidad en la que no se confía.)

Invoke-Sqlcmd -Query "SELECT COUNT(*) AS Count FROM Authors" -ConnectionString "Data Source=.;Initial Catalog=Pubs;Integrated Security=True;TrustServerCertificate=True;ApplicationIntent=ReadOnly"


Invoke-Sqlcmd -Query "SELECT COUNT(*) AS Count FROM Authors" -ConnectionString "Data Source=.;Initial Catalog=Pubs;Integrated Security=True;ApplicationIntent=ReadOnly; trusted_connection=true;encrypt=false"

Invoke-Sqlcmd -ServerInstance "localhost" -Database "Pubs" -Username "sa" -Password "sa" -Query "SELECT * FROM Authors"

#ERROR
# Invoke-Sqlcmd : A connection was successfully established with the server, but then an error occurred during the login process. (provider: SSL Provider, error: 0 - La cadena de certificación fue emitida 
# por una entidad en la que no se confía.)

Invoke-Sqlcmd -ServerInstance "localhost" -Database "Pubs" -Username "sa" -Password "sa" -Query "SELECT * FROM Authors" -TrustServerCertificate

Invoke-Sqlcmd -ServerInstance "localhost" -Database "Pubs" -Username "sa" -Password "sa" -Query "SELECT * FROM Authors" -TrustServerCertificate | ogv


Get-SqlInstance  -ServerInstance localhost

Get-SqlInstance --ServerInstance "localhost"
#ERROR

Get-SqlInstance -ServerInstance localhost | 
Invoke-SqlAssessment -Check maxmemory -FlattenOutput;


######################

# BACKUP


# Almacena los BACKUPS en C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\Backup

# Almacena los BACKUPS en C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\Backup

Backup-SqlDatabase -ServerInstance "localhost" -Database "Pubs"

Backup-SqlDatabase -ServerInstance "localhost" -Database "Northwind"

# Nota : da error cuando ya existe el Backup

Get-SqlDatabase -ServerInstance "localhost" | Where { $_.Name -eq 'Pubs' } | Backup-SqlDatabase

	
Get-SqlDatabase -ServerInstance "localhost" | Where { $_.Name -ne 'tempdb' } | Backup-SqlDatabase

# Backup completo
$dt = Get-Date -Format yyyyMMddHHmmss
$instancename = "localhost"
$dbname = 'Pubs'
Backup-SqlDatabase -Serverinstance $instancename -Database $dbname -BackupFile "c:\BACKUP\$($dbname)_db_$($dt).bak"

#Nombre del backup: Pubs_db_20231023172622.bak

#Fin backup

# Antes del restore

Invoke-Sqlcmd -Serverinstance localhost -Database Pubs -Query 'Alter Database Pubs SET SINGLE_USER WITH ROLLBACK IMMEDIATE;'

#error hay que añadir -TrustServerCertificate

Invoke-Sqlcmd -Serverinstance localhost -Database Pubs -TrustServerCertificate -Query 'Alter Database Pubs SET SINGLE_USER WITH ROLLBACK IMMEDIATE;'

Invoke-Sqlcmd -Serverinstance localhost -Database Pubs -TrustServerCertificate -Query 'Alter Database Pubs SET MULTI_USER WITH ROLLBACK IMMEDIATE;'
#borrar Pubs
Restart-Service "MSSQLSERVER" -Force

Invoke-Sqlcmd -Serverinstance localhost -Query "Drop database Pubs;"
# ERROR 

Invoke-Sqlcmd -Serverinstance localhost -TrustServerCertificate -Query "Drop database Pubs;"

#restore
Restore-Sqldatabase -Serverinstance $instancename -Database $dbname -Backupfile "C:\BACKUP\Pubs_db_20231023172622.bak" -replacedatabase
#fin restore

Invoke-Sqlcmd -ServerInstance "*" -Database "Pubs" -Username "sa" -Password "sa" -Query "SELECT * FROM Authors" 


# Ejecutar SQL con Invoke-SqlCmd con un SCRIPT

Invoke-SqlCmd -ServerInstance localhost -InputFile "C:\DATABASES EXAMPLES\Create_MyDatabase.sql"














# Comprobación de si tengo instalado SQL Server
Get-InstalledModule -Name "SqlServer"
Install-Module -Name "SqlServer"

#NOSQLPS
Import-Module -Name SqlServer

Get-InstalledModule -Name "SqlServer"

Get-Command -Module SqlServer 



#Crea los directorios C:\Scripts y C:\BD
New-Item "C:\Scripts" -ItemType Directory
New-Item "C:\BD" -ItemType Directory




