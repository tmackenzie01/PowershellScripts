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

# Global variables
$tsqlBackupsLocation = "$mydocs\Customer DBs"
$tsqlAutomaticBackupLocation = "$tsqlBackupsLocation\Automatic backups"
$tsqlDemoRoomBackupLocation = "$tsqlBackupsLocation\Demo Room"
$pcName = "$env:computername"
$powershellIncludeDirectory = "${env:ProgramData}\WindowsPowerShell includes"

# Dependencies
Write-Host "Loading dependencies..."
[System.Reflection.Assembly]::LoadWithPartialName("System.Web.Extensions") > $null

# Load data
Write-Host "Loading data..."
if (([System.IO.Directory]::Exists("$powershellIncludeDirectory"))) {
  # Load db info
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
function Tsql ($query) {
  sqlcmd -S lpc:$pcName\SQLEXPRESS -d VMS_DevConfig -Q $query
}
function Tsql-Show-Tables () {
  sqlcmd -S lpc:$pcName\SQLEXPRESS -d VMS_DevConfig -Q "SELECT Table_name FROM Information_schema.Tables ORDER BY Table_name"
}
function Tsql-Show-Columns ($tableName) {
  sqlcmd -S lpc:$pcName\SQLEXPRESS -d VMS_DevConfig -Q "select column_name from information_schema.columns WHERE table_name = '$tableName' order by table_name, ordinal_position"
}

function Tsql-Open-Backups() {
  explorer $tsqlBackupsLocation
}

function Tsql-Restore-Backup ($backup) {
  $performRestore = $TRUE # Could just use $backup and check for null/empty, but good to have a boolean example in here
  $reason = ""
  
  # Check if database exists, don't restore if already exists
  if (!($queryResults -contains "VMS_DevConfig")) {
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
  else {
    $reason = "database already exists - delete it first"
	$performRestore = $FALSE
  }
  
  if ($performRestore -eq $TRUE) {
    Write-Host "Restoring " $backup
    	
    # If the backup is an old version that stored the ldf & mdf in Program Files then we need to explicitly move it to C:\ProgramData\Titan\Database
    # SQL Server Server Management Studio does this bit automatically under the bonnet!
	
    $query = "SELECT name FROM master..sysdatabases WHERE name <> 'tempdb' AND name <> 'model' AND name <> 'msdb'"
    $queryResults = sqlcmd -S lpc:$pcName\SQLEXPRESS -Q "$nocount;$query" -W -h -1
    $move = "WITH MOVE 'VMS_DevConfig_dat' TO 'C:\ProgramData\Titan\Database\VMS_DevConfig.mdf', MOVE 'VMS_DevConfig_log' TO 'C:\ProgramData\Titan\Database\VMS_DevConfig.ldf'"
    sqlcmd -S lpc:$pcName\SQLEXPRESS -Q "RESTORE DATABASE VMS_DevConfig FROM DISK = '$backup' $move"
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
function Tsql-Delete-Database($arg) {
  $ldf = $dbInfo.DatabaseLdf
  $mdf = $dbInfo.DatabaseMdf
  $confirmation = Read-Host "This will delete VMS_DevConfig, do you want to continue? (y/n)"
  If ($confirmation -Match 'y') {
    Write-Host "Database VMS_DevConfig deletion in progress ..."
    sqlcmd -b -S lpc:$pcName\SQLEXPRESS -Q "DROP DATABASE VMS_DevConfig"
	$sqlReturnCode = $LASTEXITCODE
	
	if ($sqlReturnCode -eq 0) {
      Write-Host "Database VMS_DevConfig deleted"
	}
	else {
      if ($arg -eq "force") {
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
	  Write-Host "Use force parameter to force delete"
	}
    if (([System.IO.File]::Exists($mdf))) {
	  Write-Host "Database MDF file still exists - $mdf"
	  Write-Host "Use force parameter to force delete"
	}
  }
  else {
    Write-Host "No database VMS_DevConfig deletion performed"
  }
}

function Tsql-List-Databases() {
  # "SET NOCOUNT ON" means the "(N rows affected)" at the bottom of the query is not displayed
  $nocount = "SET NOCOUNT ON"
  # -W removes trailing spaces, -h -1 specifies no headers to be shown, https://msdn.microsoft.com/en-us/library/ms162773.aspx 
  $query = "SELECT name FROM master..sysdatabases WHERE name <> 'tempdb' AND name <> 'model' AND name <> 'msdb'"
  $queryResults = sqlcmd -S lpc:$pcName\SQLEXPRESS -Q "$nocount;$query" -W -h -1
  if ($queryResults -contains "VMS_DevConfig") {
    # Get the version number
    $versionNumber = sqlcmd -S lpc:$pcName\SQLEXPRESS -d VMS_DevConfig -Q "SET NOCOUNT ON;SELECT major_number, minor_number, revision FROM tblVersionNumber WHERE is_current=1;SET NOCOUNT OFF" -W -h -1
	$versionNumber = $versionNumber -replace " ","."
	
	# Confirm we are looking at a database which has the build_type (introduced in 6.18)
	$buildTypeExists = sqlcmd -S lpc:$pcName\SQLEXPRESS -d VMS_DevConfig -Q "IF COL_LENGTH('tblVersionNumber','build_type') IS NOT NULL BEGIN PRINT 'EXISTS' END" -W -h -1
	
	if ($buildTypeExists -eq "EXISTS") {
	  #Get the build type (case statement converts it from number to text)
      $buildType = sqlcmd -S lpc:$pcName\SQLEXPRESS -d VMS_DevConfig -Q "SET NOCOUNT ON;SELECT CASE WHEN build_type = 1 THEN 'Titan/GeoLog Secure' WHEN build_type = 2 THEN 'Titan Standard' WHEN build_type = 4 THEN 'Insecure' ELSE 'Unknown' END FROM tblVersionNumber WHERE is_current=1" -W -h -1	
	  $buildType = " $buildType"
    }
	
	# Get the migration state as well (introduced in 6.25)
	$migrationStageExists = sqlcmd -S lpc:$pcName\SQLEXPRESS -d VMS_DevConfig -Q "IF COL_LENGTH('tblVersionNumber','mediaMigrationStage') IS NOT NULL BEGIN PRINT 'EXISTS' END" -W -h -1
	
	if ($migrationStageExists -eq "EXISTS") {
	  #Get the build type (case statement converts it from number to text)
      $migrationStage = sqlcmd -S lpc:$pcName\SQLEXPRESS -d VMS_DevConfig -Q "SET NOCOUNT ON;SELECT mediaMigrationStage FROM tblVersionNumber WHERE is_current=1" -W -h -1	
	  $migrationStageText = " (migration stage $migrationStage)"
    }
	  
	$queryResults = "VMS_DevConfig" + " " + $versionNumber + $buildType + $migrationStageText 
	
	$hardwareCount = sqlcmd -S lpc:$pcName\SQLEXPRESS -d VMS_DevConfig -Q "SET NOCOUNT ON;SELECT COUNT(*) FROM tblHardware" -W -h -1
	$stationCount = sqlcmd -S lpc:$pcName\SQLEXPRESS -d VMS_DevConfig -Q "SET NOCOUNT ON;SELECT COUNT(*) FROM tblVStation" -W -h -1
	$alarmCount = sqlcmd -S lpc:$pcName\SQLEXPRESS -d VMS_DevConfig -Q "SET NOCOUNT ON;SELECT COUNT(*) FROM tblAlarm" -W -h -1
	$alarmActionCount = sqlcmd -S lpc:$pcName\SQLEXPRESS -d VMS_DevConfig -Q "SET NOCOUNT ON;SELECT COUNT(*) FROM tblAlarmAction" -W -h -1
	$summaryText1 = "$hardwareCount devices, $stationCount clients, $alarmCount alarms ($alarmActionCount actions)"
	
	$cameraCount = sqlcmd -S lpc:$pcName\SQLEXPRESS -d VMS_DevConfig -Q "SET NOCOUNT ON;SELECT COUNT(*) FROM tblCamera" -W -h -1
	$codecCount = sqlcmd -S lpc:$pcName\SQLEXPRESS -d VMS_DevConfig -Q "SET NOCOUNT ON;SELECT COUNT(*) FROM tblCodec" -W -h -1
	$panelCount = sqlcmd -S lpc:$pcName\SQLEXPRESS -d VMS_DevConfig -Q "SET NOCOUNT ON;SELECT COUNT(*) FROM tblAlarmPanel" -W -h -1
	$zoneCount = sqlcmd -S lpc:$pcName\SQLEXPRESS -d VMS_DevConfig -Q "SET NOCOUNT ON;SELECT COUNT(*) FROM tblZone" -W -h -1
	$summaryText2 = "$cameraCount cameras, $codecCount codecs, $panelCount panels ($zoneCount zones)"
	
	$mapCount = sqlcmd -S lpc:$pcName\SQLEXPRESS -d VMS_DevConfig -Q "SET NOCOUNT ON;SELECT COUNT(*) FROM tblMap" -W -h -1
	$mapObjectCount = sqlcmd -S lpc:$pcName\SQLEXPRESS -d VMS_DevConfig -Q "SET NOCOUNT ON;SELECT COUNT(*) FROM tblMapObject" -W -h -1
	$summaryText3 = "$mapCount maps, $mapObjectCount map objects"
	
	$auditCount = sqlcmd -S lpc:$pcName\SQLEXPRESS -d VMS_DevConfig -Q "SET NOCOUNT ON;SELECT COUNT(*) FROM tblAuditServer" -W -h -1
	$summaryText4 = "$auditCount audit rows"
  }
  
  Write-Host ""
  Write-Host $queryResults
  Write-Host ""
  Write-Host $summaryText1
  Write-Host $summaryText2
  Write-Host $summaryText3
  Write-Host $summaryText4
}

function Tsql-Backup-Database() {
  # backup up database to a folder called automatic backups
  # do not delete the database, this must be done manually
  $date = Get-Date -format yyyyMMdd_HHmmss
  $versionNumber = sqlcmd -S lpc:$pcName\SQLEXPRESS -d VMS_DevConfig -Q "SET NOCOUNT ON;SELECT major_number, minor_number, revision FROM tblVersionNumber WHERE is_current=1;SET NOCOUNT OFF" -W -h -1
  $versionNumber = $versionNumber -replace " ","."
  $tag = $versionNumber + "_" + $date
  
  $backupFile = "VMS_DevConfig_$tag.bak"
  $backupLocation = "$tsqlAutomaticBackupLocation\$backupFile"
  $backUpName = "VMS_DevConfig backup"
  Write-Host "Backing up to $backupFile"
  Tsql "BACKUP DATABASE VMS_DevConfig TO DISK = '$backupLocation' WITH FORMAT, MEDIANAME = 'MyBackups', NAME = '$backupName'"
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

function BareTail($log) {
  $bareTailExe = "${env:ProgramFiles(x86)}\BareTail\baretail.exe"
  # Could have made this just an alias but wanted to have -RFS and -Synergy arguments
  if ([string]::IsNullOrEmpty($log)) {
    & $bareTailExe
  }
  else {
    if ($log -Match 'RFS') {
	  $rfsLogsPath = "${env:ALLUSERSPROFILE}\Titan\Logs\RFS"
	  $rfsLogs = Get-ChildItem -Path $rfsLogsPath | Sort-Object LastWriteTime -descending | Select-Object -first 10
	  Write-Host $rfsLogs[0]
	  $firstLog = $rfsLogsPath + "\" + $rfsLogs[0]
	  Write-Host "Opening " $firstLog "..."
      & $bareTailExe $firstLog
	}
	else {
	  if ($log -Match 'Synergy') {
	    & $bareTailExe "C:\Program Files\Synergy\synergyd.log"
      }
	}
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

function sign ($filename) {
  $cert = @(gci cert:\currentuser\My -codesign)[0]
  Set-AuthenticodeSignature $filename $cert
}
