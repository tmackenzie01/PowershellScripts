$output = ""
$powershellIncludeDirectory = "${env:ProgramData}\WindowsPowerShell includes"
$dbInfoLoaded = $false

if (([System.IO.Directory]::Exists("$powershellIncludeDirectory"))) {
  # Load db info
  # To access properties of $ dbInfo when inside a string use "$($dbInfo.DatabaseName)"
  # For some reason I can't get this to work inside a sqlcmd call so have to
  # use messy alias variables like in Tsql-List-Databases
  if (([System.IO.File]::Exists("$powershellIncludeDirectory\DatabaseInfo.json"))) {
    #Write-Host "Loading data..."
    $dbInfoJson = Get-Content "$powershellIncludeDirectory\DatabaseInfo.json"
    $jsonSerializer = New-Object System.Web.Script.Serialization.JavaScriptSerializer
    $dbInfo = $jsonSerializer.DeserializeObject($dbInfoJson)
    $dbInfoLoaded = $true
  }
  else {
    $output = "Db info not found`r`n"
  }
}

if ($dbInfoLoaded -eq $true) {
  $thisIp = (gwmi Win32_NetworkAdapterConfiguration | ? { $_.IPAddress -ne $null } | Select-Object -first 1)
  $ip = $thisIp.IPAddress[0]
  $output = $output + "Setting Server with IP address $ip to be Main Server"
  $dbSn = $dbInfo.dbSn
  
  tsql "UPDATE $dbSn SET node_type = 2"
  tsql "UPDATE $dbSn SET node_type = 3 WHERE IP = '$ip'"
}

return $output