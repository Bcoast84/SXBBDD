Get-InstalledModule -Name "SqlServer"

Install-Module -Name "SqlServer"

New-Item "C:\Scripts" -itemType Directory

# Crear Bd ejecutando Script con cmdlet Invoke-SqlCmd

Invoke-SqlCmd -ServerInstance localhost -InputFile C:\scripts\CrearBD_input.sql -TrustServerCertificate

# testar conectividad a una determinada BFdbatools

Get-DbaDatabase -SqlInstance localhost -Database BD_input

<#
 Name                 Status           Size     Space  Recovery Compat. Owner                     Collation                      Containment 
                                            Available  Model     Level                                                          Type        
----                 ------           ---- ---------- -------- ------- -----                     ---------                      ------------
BD_input             Normal       16,00 MB    5,64 MB Full         150 DESKTOP-V9719B2\ccm       Modern_Spanish_CI_AS           None        
 

#>

Invoke-SqlCmd -ServerInstance localhost -Query "DROP DATABASE BD_input" -TrustServerCertificate

Get-DbaDatabase -SqlInstance localhost -Database BD_input

<#

Name                 Status           Size     Space  Recovery Compat. Owner                     Collation                      Containment 
                                            Available  Model     Level                                                          Type        
----                 ------           ---- ---------- -------- ------- -----                     ---------                      ------------
BD_input             Normal       16,00 MB    5,64 MB Full         150 DESKTOP-V9719B2\ccm       Modern_Spanish_CI_AS           None        

#>


##############################

# Crear Bd usando SQL Dinámico

New-Item "C:\BD" -itemType Directory

# create variable with SQL to execute
$sql = "
CREATE DATABASE [MyDatabase]
 CONTAINMENT = NONE
 ON  PRIMARY
( NAME = N'MyDatabase', FILENAME = N'C:\BD\MyDatabase.mdf' , SIZE = 1048576KB , FILEGROWTH = 262144KB )
 LOG ON
( NAME = N'MyDatabase_log', FILENAME = N'C:\BD\MyDatabase_log.ldf' , SIZE = 524288KB , FILEGROWTH = 131072KB )
GO

USE [master]
GO
ALTER DATABASE [MyDatabase] SET RECOVERY SIMPLE WITH NO_WAIT
GO

ALTER AUTHORIZATION ON DATABASE::[MyDatabase] TO [sa]
GO "


Invoke-SqlCmd -ServerInstance localhost -Query $sql -TrustServerCertificate

Get-DbaDatabase -SqlInstance localhost -Database MyDatabase

<#


Name                 Status           Size     Space  Recovery Compat. Owner                     Collation                      Containment 
                                            Available  Model     Level                                                          Type        
----                 ------           ---- ---------- -------- ------- -----                     ---------                      ------------
MyDatabase           Normal         1,5 GB 1021,64 MB Simple       150 sa                        Modern_Spanish_CI_AS           None        

#>

################################

# Method # 2 - Create SQL Server Database Using PowerShell and SQL Server Management Object (SMO)
# CREANDO UNA BD USNDO POWERSHELL Y SQL SERVER MANAGEMENT OBJECT (smo)

# import SqlServer module
# Import-Module -Name "SqlServer"
 
# set instance and database name variables
$inst = "LOCALHOST"
$dbname = "db_smo"  
 
# change to SQL Server instance directory  
# Set-Location SQLSERVER:\$inst        
 
# create object and database  
$db = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Database -Argumentlist $inst, $dbname  
$db.Create()  
 
# set recovery model
$db.RecoveryModel = "simple"
$db.Alter()
 
# change owner
$db.SetOwner('sa')
 
# change data file size and autogrowth amount
foreach($datafile in $db.filegroups.files) 
{
 $datafile.size= 1048576
 $datafile.growth = 262144
 $datafile.growthtype = "kb"
 $datafile.alter()
}
 
# change log file size and autogrowth
foreach($logfile in $db.logfiles)
{
 $logfile.size= 524288
 $logfile.growth = 131072
 $logfile.growthtype = "kb"
 $logfile.alter()
} 


Get-DbaDatabase -SqlInstance localhost -Database db_smo

<#
Name                 Status           Size     Space  Recovery Compat. Owner                     Collation                      Containment 
                                            Available  Model     Level                                                          Type        
----                 ------           ---- ---------- -------- ------- -----                     ---------                      ------------
db_smo               Normal         1,5 GB 1021,64 MB Simple       150 sa                        Modern_Spanish_CI_AS           None        

#>
			
################################
# TENEMOS OTRO SCRIPT MÁS COMPLETO

# Method # 3 - Create SQL Server Database Using PowerShell and dbatools
# CREAR BD USANDO DBATOOLS

# verify you have dbatools module installed
Get-InstalledModule -Name "dbatools"	

Install-Module -Name "dbatools"



$SqlInstance = 'localhost'                                                   # SQL Server name 
$Name = 'MyDatabaseDDATOOLS'                                                                # database name
$DataFilePath = 'C:\BD\' # data file path
$LogFilePath = 'C:\BD\'  # log file path
$Recoverymodel = 'Simple'                                                           # recovery model
$Owner = 'sa'                                                                       # database owner
$PrimaryFilesize = 1024                                                             # data file initial size
$PrimaryFileGrowth = 256                                                            # data file autrogrowth amount
$LogSize = 512                                                                      # data file initial size
$LogGrowth = 128                                                                    # data file autrogrowth amount
 
 New-DbaDatabase -SqlInstance $SqlInstance -Name $Name -DataFilePath $DataFilePath -LogFilePath $LogFilePath -Recoverymodel $Recoverymodel -Owner $Owner -PrimaryFilesize $PrimaryFilesize -PrimaryFileGrowth $PrimaryFileGrowth -LogSize $LogSize -LogGrowth $LogGrowth | Out-Null

Get-DbaDatabase -SqlInstance $SqlInstance -Database $Name
