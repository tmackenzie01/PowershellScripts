# Load data
Write-Host "Loading data..."
if (([System.IO.Directory]::Exists("$powershellIncludeDirectory"))) {
  # Load db info
  # To access properties of $ dbInfo when inside a string use "$($dbInfo.DatabaseName)"
  # For some reason I can't get this to work inside a sqlcmd call so have to
  # use messy alias variables like in Tsql-List-Databases
  if (([System.IO.File]::Exists("$powershellIncludeDirectory\DatabaseInfo.json"))) {
    $dbInfoJson = Get-Content "$powershellIncludeDirectory\DatabaseInfo.json"
    $jsonSerializer = New-Object System.Web.Script.Serialization.JavaScriptSerializer
    $dbInfo = $jsonSerializer.DeserializeObject($dbInfoJson)
    $androidInfoJson = Get-Content "$powershellIncludeDirectory\AndroidInfo.json"
    $androidInfo = $jsonSerializer.DeserializeObject($androidInfoJson)
  }
  else {
    Write-Host "Db info not found"
  }
}

$dbSn = $dbInfo.dbSn
$dbSc = $dbInfo.dbSc
$thisIp = (gwmi Win32_NetworkAdapterConfiguration | ? { $_.IPAddress -ne $null } | Select-Object -first 1)
$ip = $thisIp.IPAddress[0]
$thisNodeType = sqlcmd -S lpc:$pcName\SQLEXPRESS -d $($dbInfo.DatabaseName) -Q "SET NOCOUNT ON;SELECT node_type FROM $dbSn sn INNER JOIN $dbSc sc ON sn.server_ID = sc.ID WHERE ip = '$ip';SET NOCOUNT OFF" -W -h -1
$otherNodeNodeType = sqlcmd -S lpc:$pcName\SQLEXPRESS -d $($dbInfo.DatabaseName) -Q "SET NOCOUNT ON;SELECT node_type FROM $dbSn sn INNER JOIN $dbSc sc ON sn.server_ID = sc.ID WHERE ip <> '$ip';SET NOCOUNT OFF" -W -h -1

tsql "UPDATE $dbSn SET node_type = $otherNodeNodeType FROM $dbSN sn JOIN $dbSc sc ON sn.server_ID = sc.ID WHERE ip = '$ip'"
tsql "UPDATE $dbSn SET node_type = $thisNodeType FROM $dbSN sn JOIN $dbSc sc ON sn.server_ID = sc.ID WHERE ip <> '$ip'"