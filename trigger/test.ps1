$serverName = "127.0.0.1"
$databaseName = "TEST"
$userName = "sa"
$password = "Bespin1!@"
$sqlFile = ".\trigger.sql"


sqlcmd -S $serverName -d $databaseName -U $userName -P $password -i $sqlFile -o test.log