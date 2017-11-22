tsql "IF NOT EXISTS (SELECT table_name FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'tblDatabaseLog') BEGIN CREATE TABLE tblDatabaseLog (sequence_number	int) END"

Write-Host "Main or Backup"
Write-Host "1 Main "
Write-Host "2 Backup"
$selection = Read-Host "Enter a single number"

$nodeType = -1
if ($selection -eq 1) {
  "Migrating Main Server"
  $nodeType = 2
}

if ($selection -eq 2) {
  "Migrating Main Server"
  $nodeType = 3
}

tsql "INSERT tblDatabaseLog (sequence_number) SELECT sequence_number FROM tblServerNode WHERE node_type = $nodeType"
tsql "ALTER TABLE tblServerNode DROP CONSTRAINT DF__tblServer__seque__2F25DA6B"
tsql "ALTER TABLE tblServerNode DROP COLUMN sequence_number"

tsql "SELECT * FROM tblDatabaseLog" -tidy
