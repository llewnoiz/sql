Get-ExecutionPolicy -List
Set-ExecutionPolicy RemoteSigned -Force
Set-ExecutionPolicy AllSigned -Force

$serverName = "YOUR_SERVER_NAME"
$databaseName = "YOUR_DATABASE_NAME"
$userName = "YOUR_USERNAME"
$password = "YOUR_PASSWORD"
$timestamp = [int64](Get-Date -UFormat %s)
$sqlFile = ".\trigger\trigger.sql"
$logFile = "$timestamp.log"

sqlcmd -S $serverName -d $databaseName -U $userName -P $password -i $sqlFile -o $logFile


Import-Module SqlServer

$serverName = "YOUR_SERVER_NAME"
$databaseName = "YOUR_DATABASE_NAME"
$userName = "YOUR_USERNAME"
$password = "YOUR_PASSWORD"
$sqlFileContent = Get-Content -Path "PATH_TO_YOUR_SQL_FILE.sql" -Raw

Invoke-Sqlcmd -ServerInstance $serverName -Database $databaseName -Username $userName -Password $password -Query $sqlFileContent
