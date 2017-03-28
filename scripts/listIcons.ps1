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

$dbMf = $dbInfo.dbMf
$dbMfn = $dbInfo.dbMfn
$dbMo = $dbInfo.dbMo
$dbMoi = $dbInfo.dbMoi

tsql "SELECT mo.ID, mo.map_ID, mo.text, 
mfnActive.filename AS activeMedia, 
mfnDisabled.filename as disabledMedia, 
mfnIdle.filename AS idleMedia, 
mfnTamper.filename AS tamperMedia, 
mfnAccepted.filename AS acceptedMedia FROM $dbMo mo 
INNER JOIN $dbMoi moi ON mo.ID = moi.map_object_ID  

LEFT OUTER JOIN $dbMf mfActive ON moi.active_media = mfActive.ID LEFT OUTER JOIN $dbMfn mfnActive ON mfnActive.ID = mfActive.fileID 
LEFT OUTER JOIN $dbMf mfDisabled ON moi.disabled_media = mfDisabled.ID LEFT OUTER JOIN $dbMfn mfnDisabled ON mfDisabled.fileID = mfnDisabled.ID 
LEFT OUTER JOIN $dbMf mfIdle ON moi.idle_media = mfIdle.ID LEFT OUTER JOIN $dbMfn mfnIdle ON mfIdle.fileID = mfnIdle.ID 
LEFT OUTER JOIN $dbMf mfTamper ON moi.tamper_media = mfTamper.ID LEFT OUTER JOIN $dbMfn mfnTamper ON mfTamper.fileID = mfnTamper.ID 
LEFT OUTER JOIN $dbMf mfAccepted ON moi.accepted_media = mfAccepted.ID LEFT OUTER JOIN $dbMfn mfnAccepted ON mfAccepted.fileID = mfnAccepted.ID 
ORDER BY mo.ID, mo.map_ID, moi.ID"
