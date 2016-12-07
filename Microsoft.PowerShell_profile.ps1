$major = $PSVersionTable.PSVersion.Major
$minor = $PSVersionTable.PSVersion.Minor
Write-Host "Loading profile for PowerShell $major.$minor" 

# Aliases
Set-Alias npp ${env:ProgramFiles(x86)}\Notepad++\notepad++.exe
Set-Alias ILMerge ${env:ProgramFiles(x86)}\Microsoft\ILMerge\ILMerge.exe
Set-Alias ildasm "${env:ProgramFiles(x86)}\Microsoft SDKs\Windows\v10.0A\bin\NETFX 4.6 Tools\ildasm.exe"
Set-Alias nuget "${env:ProgramFiles(x86)}\Nuget\nuget.exe"
Set-Alias mstest "${env:ProgramFiles(x86)}\Microsoft Visual Studio 14.0\Common7\IDE\MSTest.exe"
Set-Alias ffmpeg "${env:ProgramFiles(x86)}\ffmpeg\bin\ffmpeg.exe"
Set-Alias depends "${env:ProgramFiles(x86)}\Dependency Walker\Dependency Walker 2.2\depends.exe"

# Global variables
$tsqlBackupsLocation = "$mydocs\Customer DBs"
$tsqlAutomaticBackupLocation = "$tsqlBackupsLocation\Automatic backups"
$tsqlDemoRoomBackupLocation = "$tsqlBackupsLocation\Demo Room"
$tsqlTBackupsLocation = "C:\ProgramData\Titan\Backups"
$pcName = "$env:computername"
$powershellIncludeDirectory = "${env:ProgramData}\WindowsPowerShell includes"

# Dependencies
Write-Host "Loading dependencies..."
[System.Reflection.Assembly]::LoadWithPartialName("System.Web.Extensions") > $null

# Load data
Write-Host "Loading data..."
if (([System.IO.Directory]::Exists("$powershellIncludeDirectory"))) {
  # Load db info
  # To access properties of $ dbInfo when inside a string use "$($dbInfo.DatabaseName)"
  # For some reason I can't get this to work inside a sqlcmd call so have to
  # use messy alias variables like in Tsql-List-Databases
  if (([System.IO.File]::Exists("$powershellIncludeDirectory\DatabaseInfo.json"))) {
    Write-Host "Loading data..."
    $dbInfoJson = Get-Content "$powershellIncludeDirectory\DatabaseInfo.json"
    $jsonSerializer = New-Object System.Web.Script.Serialization.JavaScriptSerializer
    $dbInfo = $jsonSerializer.DeserializeObject($dbInfoJson)
  }
  else {
    Write-Host "Db info not found"
  }
}

function Get-Args($script) {
  # Opens up or creates a script file for the specified $script file
  # test.ps1 -> ${env:ProgramData}\WindowsPowerShell includes\test_args.json
  $argsFile = $script -replace ".ps1","_args.json"
  $argsFile = "$powershellIncludeDirectory\$argsFile"
  Write-Host "Opening $argsFile"
  
  if (!([System.IO.File]::Exists("$powershellIncludeDirectory\DatabaseInfo.json"))) {
    $confirmation = Read-Host "No args file exists?  Do you wish to create (y/n)"
    If ($confirmation -Match 'y') {
      npp $argsFile
    }
  }
  else {
    npp $argsFile
  }
}

# Reload profile
function Reload-Profile() {
  # This is just . $profile, but at the moment I won't remember that
  . $profile
  Write-Host "May not pick up changes for existing functions, try re-launching PowerShell"
}

function Help-Me() {
  # This is for when I forget/trying to learn stuff
  Write-Host "To see what methods and properties an cmdlet has do this"
  Write-Host "Get-Service | Get-Member"
  Write-Host ""
  Write-Host ""
}

# SQL Server functionality
function Tsql {
  Param([Parameter(Mandatory=$true)] [String]$query,
		[switch] $tidy,
		[switch] $nodatabase)
  if ($nodatabase) {
    sqlcmd -S lpc:$pcName\SQLEXPRESS -Q $query
    return
  }
  if ($tidy) {  
  
    $tempFile = [io.path]::GetTempFileName() 
    sqlcmd -S lpc:$pcName\SQLEXPRESS -d $($dbInfo.DatabaseName) -Q $query >> $tempFile
    c:\users\tmackenzie01\source\repos\tsqltidyup\tsqltidyup\tsqltidyup\bin\debug\tsqltidyup.exe $tempFile
  }
  else {
    sqlcmd -S lpc:$pcName\SQLEXPRESS -d $($dbInfo.DatabaseName) -Q $query
  }
  Write-Host $tsqlOutput
}
function Tsql-Show-Tables () {
  Param([String]$searchString,
		[switch] $count)
  $tables = sqlcmd -S lpc:$pcName\SQLEXPRESS -d $($dbInfo.DatabaseName) -Q "SELECT Table_name FROM Information_schema.Tables ORDER BY Table_name"
  $showTablesText = ""
  foreach ($table in $tables) {
    $tableName = $table.TrimEnd()
    if ($tableName.StartsWith("tbl")) {
	  $countResult = ""
      if ($count) {
        # Add the row count to each result    
	    $countResult = sqlcmd -S lpc:$pcName\SQLEXPRESS -d $($dbInfo.DatabaseName) -Q "SELECT COUNT(*) FROM $tableName"
		# sqlcmd will return a blank line (the blank column), an underline, data, blank line, the rows affected count
		$tableCount = $countResult[2].TrimStart().TrimEnd() + " row"
		if ($tableCount -ne 1) {
		  $tableCount = $tableCount + "s"
		}
      }
	  
      if (![string]::IsNullOrEmpty($searchString)) {
	    if ($tableName.ToLower().Contains($searchString.ToLower())) {
	      $showTablesText = $showTablesText + "$tableName $tableCount`r`n"
		}
      } else {
	      $showTablesText = $showTablesText + "$tableName $tableCount`r`n"
	  }
    }
  }
  
  return $showTablesText
}

function Tsql-Show-Columns ($tableName) {
  sqlcmd -S lpc:$pcName\SQLEXPRESS -d $($dbInfo.DatabaseName) -Q "select column_name from information_schema.columns WHERE table_name = '$tableName' order by table_name, ordinal_position"  | ForEach-Object {Write-Host $_.TrimEnd()}
}

function Tsql-Export-Database($outfile) {
  if ([string]::IsNullOrEmpty($outfile)) {
    Write-Host "Supply an outfile"
  }
  else {  
    $tables = sqlcmd -S lpc:$pcName\SQLEXPRESS -d $($dbInfo.DatabaseName) -Q "SELECT Table_name FROM Information_schema.Tables ORDER BY Table_name"
	foreach ($table in $tables) {
	  $tableName = $table.TrimEnd()
	  # Remember to skip the table that can get really large - they can do that separate if really required
	  if (($tableName.StartsWith("tbl")) -and ($tableName -ne "$($dbInfo.dbAu)")) {
        Write-Host "Fetching from $tableName"
        "Fetching from $tableName" >> $outfile
        sqlcmd -S lpc:$pcName\SQLEXPRESS -d $($dbInfo.DatabaseName) -Q "SELECT '$tableName', * FROM $tableName" >> $outfile
	  }
	}
  }
}

function Tsql-Open-Backups() {
  explorer $tsqlBackupsLocation
}

function Tsql-Restore-Backup ($backup,
		[switch] $previous) {
  $performRestore = $TRUE # Could just use $backup and check for null/empty, but good to have a boolean example in here
  $reason = ""
  $databaseDat = $dbInfo.DatabaseName + "_dat"
  $databaseLog = $dbInfo.DatabaseName + "_log"
  
  # Check if database exists, don't restore if already exists
  if (!($queryResults -contains "$dbInfo.DatabaseName")) {
    # If previous switch set then use the latest database backup in 
    if ($previous) {
      $lastBackup = Get-ChildItem -Path $tsqlTBackupsLocation | Sort-Object LastWriteTime -descending | Select-Object -first 1
      $backup = "$tsqlTBackupsLocation\" + $lastBackup
      $performRestore = $TRUE
	}
	else {
      # If no parameter is passed in then look at the automatic backups
	  if ([string]::IsNullOrEmpty($backup)) {
  	    # No backup file supplied, list the most recent backups in the automatic backup folder
        # prompt which one (by number) to restore
	    Write-Host "Select a backup"
        $files = Get-ChildItem -Path $tsqlAutomaticBackupLocation | Sort-Object LastWriteTime -descending | Select-Object -first 10
	    [int]$fileCount = 1
        ForEach ($f in $files) {
	      Write-Host "$fileCount $f"
		  $fileCount++
	    }
	    $filesLength = $files.Length
        [int]$val = Read-Host "Enter 1 to $filesLength to restore most recent backup" # Add error handling for non-ints later
	  
        if (($val -ge 1) -and ($val -le $filesLength)) {
          $file = $files[$val - 1]
          $backup = "$tsqlAutomaticBackupLocation\" + $file.Name
		  $performRestore = $TRUE
        }
        else {
          $reason = "no valid backup selected"
		  $performRestore = $FALSE
		}
      }
	}
  }
  else {
    $reason = "database already exists - delete it first"
	$performRestore = $FALSE
  }
  
  if ($performRestore -eq $TRUE) {
    Write-Host "Restoring " $backup
    	
    # If the backup is an old version that stored the ldf & mdf in Program Files then we need to explicitly move it to C:\ProgramData\Titan\Database
    # SQL Server Server Management Studio does this bit automatically under the bonnet!
	
	$ldf = $dbInfo.DatabaseLdf
	$mdf = $dbInfo.DatabaseMdf
    $query = "SELECT name FROM master..sysdatabases WHERE name <> 'tempdb' AND name <> 'model' AND name <> 'msdb'"
    $queryResults = sqlcmd -S lpc:$pcName\SQLEXPRESS -Q "$nocount;$query" -W -h -1
    $move = "WITH MOVE '$databaseDat' TO '$mdf', MOVE '$databaseLog' TO '$ldf'"
    sqlcmd -S lpc:$pcName\SQLEXPRESS -Q "RESTORE DATABASE $($dbInfo.DatabaseName) FROM DISK = '$backup' $move"
  }
  else {
    Write-Host "Restore not performed, $reason"
  }
}

function Tsql-Restore-Backup-Demo () {
  Write-Host "Restoring latest demo room backup from $tsqlDemoRoomBackupLocation"
  # come back later
}

# This accepts argument "force" to delete mdf & ldf files
function Tsql-Delete-Database {
  Param([switch] $force)
  $ldf = $dbInfo.DatabaseLdf
  $mdf = $dbInfo.DatabaseMdf
  $confirmation = Read-Host "This will delete $($dbInfo.DatabaseName), do you want to continue? (y/n)"
  If ($confirmation -Match 'y') {
    Write-Host "Database $($dbInfo.DatabaseName) deletion in progress ..."
    sqlcmd -b -S lpc:$pcName\SQLEXPRESS -Q "DROP DATABASE $($dbInfo.DatabaseName)"
	$sqlReturnCode = $LASTEXITCODE
	
	if ($sqlReturnCode -eq 0) {
      Write-Host "Database $($dbInfo.DatabaseName) deleted"
	}
	else {
      if ($force) {
        Write-Host "Deleting ldf & mdf files"	
        if (([System.IO.File]::Exists($ldf))) {
          [System.IO.File]::Delete($ldf)
		}	
        if (([System.IO.File]::Exists($mdf))) {
          [System.IO.File]::Delete($mdf)
		}
      }
	}
	
	# Check if mdf or ldf still exist
    if (([System.IO.File]::Exists($ldf))) {
	  Write-Host "Database LDF file still exists - $ldf"
	  Write-Host "Use -force parameter to force delete"
	}
    if (([System.IO.File]::Exists($mdf))) {
	  Write-Host "Database MDF file still exists - $mdf"
	  Write-Host "Use -force parameter to force delete"
	}
  }
  else {
    Write-Host "No database deletion performed"
  }
}

function Tsql-List-Databases([switch] $verbose) {
  $dbH = $dbInfo.dbH
  $dbHNameSingular = $dbInfo.dbHNameSingular
  $dbHNamePlural = $dbInfo.dbHNamePlural
  $dbVS = $dbInfo.dbVS
  $dbVSNameSingular = $dbInfo.dbVSNameSingular
  $dbVSNamePlural = $dbInfo.dbVSNamePlural
  $dbA = $dbInfo.dbA
  $dbAANameSingular = $dbInfo.dbANameSingular
  $dbANamePlural = $dbInfo.dbANamePlural
  $dbAA = $dbInfo.dbAA
  $dbAANameSingular = $dbInfo.dbAANameSingular
  $dbAANamePlural = $dbInfo.dbAANamePlural
  $dbCa = $dbInfo.dbCa
  $dbCaNameSingular = $dbInfo.dbCaNameSingular
  $dbCaNamePlural = $dbInfo.dbCaNamePlural
  $dbCo = $dbInfo.dbCo
  $dbCoNameSingular = $dbInfo.dbCoNameSingular
  $dbCoNamePlural = $dbInfo.dbCoNamePlural
  $dbAp = $dbInfo.dbAp
  $dbApNameSingular = $dbInfo.dbApNameSingular
  $dbApNamePlural = $dbInfo.dbApNamePlural
  $dbZ = $dbInfo.dbZ
  $dbZNameSingular = $dbInfo.dbZNameSingular
  $dbZNamePlural = $dbInfo.dbZNamePlural
  $dbM = $dbInfo.dbM
  $dbMNameSingular = $dbInfo.dbMNameSingular
  $dbMNamePlural = $dbInfo.dbMNamePlural
  $dbMo = $dbInfo.dbMo
  $dbMoNameSingular = $dbInfo.dbMoNameSingular
  $dbMoNamePlural = $dbInfo.dbMoNamePlural
  $dbAu = $dbInfo.dbAu
  $dbAuNameSingular = $dbInfo.dbAuNameSingular
  $dbAuNamePlural = $dbInfo.dbAuNamePlural
  $dbRc = $dbInfo.dbRc
  $dbRcNameSingular = $dbInfo.dbRcNameSingular
  $dbRcNamePlural = $dbInfo.dbRcNamePlural
  $dbSp = $dbInfo.dbSp
  $dbSpNameSingular = $dbInfo.dbSpNameSingular
  $dbSpNamePlural = $dbInfo.dbSpNamePlural
  $dbSn = $dbInfo.dbSn
  $dbV = $dbInfo.dbV
  $listDatabasesSpecialQuery1 = $dbInfo.listDatabasesSpecialQuery1
  
  # "SET NOCOUNT ON" means the "(N rows affected)" at the bottom of the query is not displayed
  $nocount = "SET NOCOUNT ON"
  # -W removes trailing spaces, -h -1 specifies no headers to be shown, https://msdn.microsoft.com/en-us/library/ms162773.aspx 
  $query = "SELECT name FROM master..sysdatabases WHERE name <> 'tempdb' AND name <> 'model' AND name <> 'msdb'"
  $queryResults = sqlcmd -S lpc:$pcName\SQLEXPRESS -Q "$nocount;$query" -W -h -1
  if ($queryResults -contains "$($dbInfo.DatabaseName)") {    
    $databasePresent = $TRUE
    # Get the version number
    $versionNumber = sqlcmd -S lpc:$pcName\SQLEXPRESS -d $($dbInfo.DatabaseName) -Q "SET NOCOUNT ON;SELECT major_number, minor_number, revision FROM $dbV WHERE is_current=1;SET NOCOUNT OFF" -W -h -1
	$versionNumber = $versionNumber -replace " ","."
	
	# Confirm we are looking at a database which has the build_type (introduced in 6.18)
	$buildTypeExists = sqlcmd -S lpc:$pcName\SQLEXPRESS -d $($dbInfo.DatabaseName) -Q "IF COL_LENGTH('$dbV','build_type') IS NOT NULL BEGIN PRINT 'EXISTS' END" -W -h -1
	
	if ($buildTypeExists -eq "EXISTS") {
	  #Get the build type (case statement converts it from number to text)
      $buildType = sqlcmd -S lpc:$pcName\SQLEXPRESS -d $($dbInfo.DatabaseName) -Q "SET NOCOUNT ON;SELECT CASE WHEN build_type = 1 THEN 'Titan/GeoLog Secure' WHEN build_type = 2 THEN 'Titan Standard' WHEN build_type = 4 THEN 'Insecure' ELSE 'Unknown' END FROM $dbV WHERE is_current=1" -W -h -1	
	  $buildType = " $buildType"
    }
	
	# Get the migration state as well (introduced in 6.25)
	$migrationStageExists = sqlcmd -S lpc:$pcName\SQLEXPRESS -d $($dbInfo.DatabaseName) -Q "IF COL_LENGTH('$dbV','mediaMigrationStage') IS NOT NULL BEGIN PRINT 'EXISTS' END" -W -h -1
	
	if ($migrationStageExists -eq "EXISTS") {
	  #Get the build type (case statement converts it from number to text)
      $migrationStage = sqlcmd -S lpc:$pcName\SQLEXPRESS -d $($dbInfo.DatabaseName) -Q "SET NOCOUNT ON;SELECT mediaMigrationStage FROM $dbV WHERE is_current=1" -W -h -1	
	  $migrationStageText = " (migration stage $migrationStage)"
    }
	
	# Is it a Main or Backup Server
	$snTypeText = " (Unknown server node type) Server"
	$snExists = sqlcmd -S lpc:$pcName\SQLEXPRESS -d $($dbInfo.DatabaseName) -Q "IF COL_LENGTH('$dbSn','Name') IS NOT NULL BEGIN PRINT 'EXISTS' END" -W -h -1
	
	if ($snExists -eq "EXISTS") {
	  $thisIp = (gwmi Win32_NetworkAdapterConfiguration | ? { $_.IPAddress -ne $null } | Select-Object -first 1)
	  $ip = $thisIp.IPAddress[0]
	  $snCount = sqlcmd -S lpc:$pcName\SQLEXPRESS -d $($dbInfo.DatabaseName) -Q "SET NOCOUNT ON;SELECT COUNT(*) FROM $dbSn;SET NOCOUNT OFF" -W -h -1
	  $snType = sqlcmd -S lpc:$pcName\SQLEXPRESS -d $($dbInfo.DatabaseName) -Q "SET NOCOUNT ON;SELECT node_type FROM $dbSn WHERE ip = '$ip';SET NOCOUNT OFF" -W -h -1
	  if (($snType -eq 3) -and ($snCount -lt 3)) {
	    $snTypeText = " Backup Server"
	  }
	  else {
	    if (($snType -eq 2) -and ($snCount -eq 2)) {
  	      $snTypeText = " Main Server"
		}
		else {
		  if ($snCount -eq 0) {
			$snTypeText = " Standalone Server"
		  }
		  else {
		    $snTypeText = " (Unknown server node type) Server ($snType)"
		  }
		}
	  }
	}
	  
	$queryResults = "$($dbInfo.DatabaseName)" + " " + $versionNumber + $buildType + $snTypeText + $migrationStageText
	
	$hCount = sqlcmd -S lpc:$pcName\SQLEXPRESS -d $($dbInfo.DatabaseName) -Q "SET NOCOUNT ON;SELECT COUNT(*) FROM $dbH" -W -h -1
	$spCount = sqlcmd -S lpc:$pcName\SQLEXPRESS -d $($dbInfo.DatabaseName) -Q "SET NOCOUNT ON;SELECT COUNT(*) FROM $dbSp" -W -h -1
	$vsCount = sqlcmd -S lpc:$pcName\SQLEXPRESS -d $($dbInfo.DatabaseName) -Q "SET NOCOUNT ON;SELECT COUNT(*) FROM $dbVS" -W -h -1
	$aCount = sqlcmd -S lpc:$pcName\SQLEXPRESS -d $($dbInfo.DatabaseName) -Q "SET NOCOUNT ON;SELECT COUNT(*) FROM $dbA" -W -h -1
	$aaCount = sqlcmd -S lpc:$pcName\SQLEXPRESS -d $($dbInfo.DatabaseName) -Q "SET NOCOUNT ON;SELECT COUNT(*) FROM $dbAA" -W -h -1
	$summaryText1 = "$hCount $dbHNamePlural, $vsCount $dbVSNamePlural, $spCount $dbSpNamePlural, $aCount $dbANamePlural ($aaCount $dbAANamePlural)"
		
	$caCount = sqlcmd -S lpc:$pcName\SQLEXPRESS -d $($dbInfo.DatabaseName) -Q "SET NOCOUNT ON;SELECT COUNT(*) FROM $dbCa" -W -h -1
	$coCount = sqlcmd -S lpc:$pcName\SQLEXPRESS -d $($dbInfo.DatabaseName) -Q "SET NOCOUNT ON;SELECT COUNT(*) FROM $dbCo" -W -h -1
	$rcCount = sqlcmd -S lpc:$pcName\SQLEXPRESS -d $($dbInfo.DatabaseName) -Q "SET NOCOUNT ON;SELECT COUNT(*) FROM $dbRc" -W -h -1
	$summaryText2 = "$caCount $dbCaNamePlural, $coCount $dbCoNamePlural ($rcCount $dbRcNamePlural)"
	
	$apCount = sqlcmd -S lpc:$pcName\SQLEXPRESS -d $($dbInfo.DatabaseName) -Q "SET NOCOUNT ON;SELECT COUNT(*) FROM $dbAp" -W -h -1
	$zCount = sqlcmd -S lpc:$pcName\SQLEXPRESS -d $($dbInfo.DatabaseName) -Q "SET NOCOUNT ON;SELECT COUNT(*) FROM $dbZ" -W -h -1
	$summaryText3 = "$apCount $dbApNamePlural ($zCount $dbZNamePlural)"
	
	$mCount = sqlcmd -S lpc:$pcName\SQLEXPRESS -d $($dbInfo.DatabaseName) -Q "SET NOCOUNT ON;SELECT COUNT(*) FROM $dbM" -W -h -1
	$moCount = sqlcmd -S lpc:$pcName\SQLEXPRESS -d $($dbInfo.DatabaseName) -Q "SET NOCOUNT ON;SELECT COUNT(*) FROM $dbMo" -W -h -1
	$summaryText4 = "$mCount $dbMNamePlural, $moCount $dbMoNamePlural"
	
	$auCount = sqlcmd -S lpc:$pcName\SQLEXPRESS -d $($dbInfo.DatabaseName) -Q "SET NOCOUNT ON;SELECT COUNT(*) FROM $dbAu" -W -h -1
	$summaryText5 = "$auCount $dbAuNamePlural"
	
	if ($verbose) {
	  $verboseText1Heading = "$spCount $dbSpNamePlural:"
	  $verboseText1Result = sqlcmd -S lpc:$pcName\SQLEXPRESS -d $($dbInfo.DatabaseName) -Q "SET NOCOUNT ON; $listDatabasesSpecialQuery1" -W -h -1
	  $verboseText1 = $verboseText1Heading + $verboseText1Result
	}
  }
    
  if ($databasePresent -eq $TRUE) {
    Write-Host ""
    Write-Host $queryResults
    Write-Host ""
    Write-Host $summaryText1
    Write-Host $summaryText2
    Write-Host $summaryText3
    Write-Host $summaryText4
    Write-Host $summaryText5
  
    if ($verbose) {
      Write-Host ""
	  Write-Host $verboseText1
    }
  }
  else {
    Write-Host $queryResults
  }
}

function Tsql-Backup-Database() {
  $dbV = $dbInfo.dbV
  
  # backup up database to a folder called automatic backups
  # do not delete the database, this must be done manually
  $date = Get-Date -format yyyyMMdd_HHmmss
  $versionNumber = sqlcmd -S lpc:$pcName\SQLEXPRESS -d $($dbInfo.DatabaseName) -Q "SET NOCOUNT ON;SELECT major_number, minor_number, revision FROM $dbV WHERE is_current=1;SET NOCOUNT OFF" -W -h -1
  $versionNumber = $versionNumber -replace " ","."
  $tag = $versionNumber + "_" + $date
  
  $backupFile = "$($dbInfo.DatabaseName)_$tag.bak"
  $backupLocation = "$tsqlAutomaticBackupLocation\$backupFile"
  $backUpName = "$($dbInfo.DatabaseName) backup"
  Write-Host "Backing up to $backupFile"
  Tsql "BACKUP DATABASE $($dbInfo.DatabaseName) TO DISK = '$backupLocation' WITH FORMAT, MEDIANAME = 'MyBackups', NAME = '$backupName'"
}

function Tsql-Tips() {
  # Some TSQL stuff which I always forget
  Write-Host "Get top 100 rows of a table:"
  Write-Host "SELECT TOP 100 * FROM TABLE"  
}

function Get-OEM($name) {
  if ([string]::IsNullOrEmpty($name)) {
    Write-Host "Missing subkey T****"
  }
  else {  
    $currentOEM = Get-ItemProperty -Path HKLM:\SOFTWARE\Wow6432Node\$name\All -Name OEM
	$oemValue = $currentOEM.OEM
	$oemHint = ""
    switch ($oemValue) {
      "1" {$oemHint = "normal"}
      "2" {$oemHint = "Ge - only if Secure"}
      "3" {$oemHint = "El"}
      "4" {$oemHint = "B"}
      "5" {$oemHint = "WS"}
      "6" {$oemHint = "N"}
      "7" {$oemHint = "A"}
      default {$oemHint = "Unsupported"}
    }
    Write-Host "Current OEM is $oemValue - $oemHint"
  }
}

function Set-OEM($name, $val) {
  if ([string]::IsNullOrEmpty($name)) {
    Write-Host "Missing subkey T****"
  }
  else {  
    if ([string]::IsNullOrEmpty($val)) {
      Write-Host "Missing subkey T**** and/or value (1-7)"
    }
	else {
      Set-ItemProperty -Path HKLM:\SOFTWARE\Wow6432Node\$name\All -Name OEM -Value $val
	  Get-OEM($name)
	}
  }
}

function ffmpeg-capture-rtsp($rtspPath, $outputFile) {
  if ([string]::IsNullOrEmpty($rtspPath)) {
    Write-Host "Specify 1st param RTSP path, for example - rtsp://172.16.2.69:554/axis-media/media.amp"
  }
  
  if ([string]::IsNullOrEmpty($outputFile)) {
    Write-Host "Specify 2nd param output file"
  }
  #ffmpeg -f rtsp -i rtsp://172.16.2.121:554/ch0_unicast_firststream out2.mp4 -loglevel debug
  #ffmpeg -t 00:00:30 -f rtsp -i rtsp://172.16.2.69:554/axis-media/media.amp -an -pass 1 -vcodec libx264 -b 180000 -bt 180000 -threads 0 -y outfile.mp4
  ffmpeg -t 00:00:30 -f rtsp -i $rtspPath -an -pass 1 -vcodec libx264 -b 180000 -bt 180000 -threads 0 -y $outputFile
}

function Synergy-Log($rowCount) {
  if ([string]::IsNullOrEmpty($rowCount)) {
    $rowCount = 30
  }
  $logFilename = "C:\Program Files\Synergy\synergyd.log"
  Write-Host "Last $rowCount lines from $logFilename ..."
  Get-Content $logFilename | Where-Object { $_ -ne '' } | Select -Last $rowCount
}

function Synergy-Restart() {
  Restart-Service Synergy
  Write-Host ""
  Synergy-Log
}

function BareTail($log, [switch] $rfs, [switch] $server, [switch] $synergy) {
  $bareTailExe = "${env:ProgramFiles(x86)}\BareTail\baretail.exe"
  # Could have made this just an alias but wanted to have -RFS and -Synergy arguments
  if ($rfs) {
    $rfsLogsPath = "${env:ALLUSERSPROFILE}\Titan\Logs\RFS"
	$rfsLogs = Get-ChildItem -Path $rfsLogsPath | Sort-Object LastWriteTime -descending | Select-Object -first 10
	Write-Host $rfsLogs[0]
	$firstLog = $rfsLogsPath + "\" + $rfsLogs[0]
	Write-Host "Opening " $firstLog "..."
    & $bareTailExe $firstLog
	return
  }
  
  if ($server) {
	$serverMessages = "${env:ALLUSERSPROFILE}\Titan\Logs\ServerMessages.txt"
	Write-Host "Opening " $serverMessages "..."
    & $bareTailExe $serverMessages
	return
  }
  
  if ($log -Match 'Synergy') {
    & $bareTailExe "C:\Program Files\Synergy\synergyd.log"
	return
  }
  
  if ([string]::IsNullOrEmpty($log)) {
    & $bareTailExe
  }
}

function CapturePreviousOutput() {
  $tempFile = [io.path]::GetTempFileName() 
  Invoke-History >> $tempFile
  npp $tempFile
}

function CapturePreviousCommand() {
  $prev = (Get-History)[-1].CommandLine
  Write-Host "Previous:" $prev
  $prev | clip
}

function TidyUpTsql() {
  $tempFile = [io.path]::GetTempFileName() 
  Invoke-History >> $tempFile
  c:\users\tmackenzie01\source\repos\tsqltidyup\tsqltidyup\tsqltidyup\bin\debug\tsqltidyup.exe $tempFile
}

# Opens TortoiseSVN dialog for checkout and populates fields
function Svn-Checkout($repoPath, $codeFolder) {
  if (([string]::IsNullOrEmpty($repoPath)) -or ([string]::IsNullOrEmpty($codeFolder))) {
    Write-Host "Command is as follows:"
	Write-Host 'Svn-Checkout http://X.X.X.X/svn/CodeProject01/trunk D:\CodeSandbox'
  }
  else {
    # Use $repoPath as the default path
    $codeBuiltPath = $repoPath
	$repoPathSplit = $repoPath.Split("/")
	
	if ($repoPathSplit.Count -gt 2) {
	  if ($repoPath.EndsWith("trunk")) {
        $projectName = $repoPathSplit[$repoPathSplit.Count - 2]
        $codeBuiltPath = $codeFolder + "\" + "$projectName" + "_trunk"
      }
	  if ($repoPath.Contains("branches")) {
        $projectName = $repoPathSplit[$repoPathSplit.Count - 3]
        $branchName = $repoPathSplit[$repoPathSplit.Count - 1]
        $codeBuiltPath = $codeFolder + "\" + "$projectName" + "_branches_" + $branchName
      }
	}	
	
    TortoiseProc.exe /command:checkout /path:$codeBuiltPath /url:"$repoPath"
  }
}

# Can use this with GetFiles & ForEach-Object
# [io.directory]::GetFiles("C:\") | ForEach-Object { Rec-Time $_ }
function Rec-Time {
  Param([Parameter(Mandatory=$true)] [String]$filename, [switch] $duration)
  $filenameOnly = [io.path]::GetFilename($filename)
  
  if ($filenameOnly.EndsWith(".tmp")) {
    $tempState = " *TEMP* "
  }
  
  $year = $filenameOnly.SubString(0,2)
  $month = $filenameOnly.SubString(2,2)
  $day = $filenameOnly.SubString(4,2)
  
  $totalText = $filenameOnly.SubString(6, 8)
  $durationText = $filenameOnly.SubString(16, 3)
  $total = [int]$totalText
  
  $totalMilliseconds = $total % 1000
  $totalMillisecondsText = $totalMilliseconds.ToString().PadLeft(3, '0')
  #Write-Host "MS : $totalMilliseconds $totalMillisecondsText"
  
  $totalSeconds = $total / 1000
  $second = ($totalSeconds % 60)
  $second = [math]::floor($second)
  $secondText = $second.ToString().PadLeft(2, '0')
  #Write-Host "S : $secondText"
  $totalMinutes = $totalSeconds / 60
  $minute = ($totalMinutes  % 60)
  $minute = [math]::floor($minute)
  $minuteText = $minute.ToString().PadLeft(2, '0')
  #Write-Host "M : $minuteText"
  $hour = ($totalMinutes / 60 )
  $hour = [math]::floor($hour) 
  #Write-Host "H : $hour"
  
  if ($duration) {
    $durationSeconds = [int]$durationText
    $finalurationText = " $durationSeconds seconds"
  }
  
  # Colon is a special character so wrap the preceding variable
  return "$day-$month-20$year ${hour}:${minuteText}:$secondText.$totalMillisecondsText$finalurationText$tempState"
}

function sign ($filename) {
  $cert = @(gci cert:\currentuser\My -codesign)[0]
  Set-AuthenticodeSignature $filename $cert
}

function grep($searchString) {
  Write-Host "Output from: Select-String .\*.* -Pattern ""$searchstring"""
  Select-String .\*.* -Pattern "$searchstring"
}