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

$dbM = $dbInfo.dbM
$dbMf = $dbInfo.dbMf
$dbMo = $dbInfo.dbMo
$dbMoi = $dbInfo.dbMoi

$i = 1;
$j = 1;

$mapLimit = 300;
$iconsPerMap = 10;

do 
{  
  # Map image
  tsql "INSERT INTO $dbMf VALUES ('$i.png')"
  $newImageID = sqlcmd -S lpc:$pcName\SQLEXPRESS -d $($dbInfo.DatabaseName) -Q "SET NOCOUNT ON;SELECT TOP 1 ID FROM $dbMf WHERE filename = '$i.png';SET NOCOUNT OFF" -W -h -1
  Write-Host "Added map image $i.png, ID $newImageID"
  
  # Map
  tsql "INSERT INTO $dbM VALUES ('Map $i', '', $newImageID, 0, 1, 1, 1, 1, 1, 1)"
  $newMapID = sqlcmd -S lpc:$pcName\SQLEXPRESS -d $($dbInfo.DatabaseName) -Q "SET NOCOUNT ON;SELECT TOP 1 ID FROM $dbM WHERE name = 'Map $i';SET NOCOUNT OFF" -W -h -1
  #Write-Host "Added map Map $i, ID $newMapID"
    
  #Write-Host "Copy map to $mapDest"
  $mapDest = "C:\Program Files (x86)\Titan\Vision Server\sites\default\maps\$i.png"
  Copy-Item D:\map1.png $mapDest

  $j = 1;
  do
  {
    $iconFilename = "$i $j.png"
	#Write-Host "Icon filename is $iconFilename"
  
    # Icon image
    tsql "INSERT INTO $dbMf VALUES ('\\127.0.0.1\VISION\maps\icons\$iconFilename')"
    $newImageID = sqlcmd -S lpc:$pcName\SQLEXPRESS -d $($dbInfo.DatabaseName) -Q "SET NOCOUNT ON;SELECT TOP 1 ID FROM $dbMf WHERE filename = '\\127.0.0.1\VISION\maps\icons\$iconFilename';SET NOCOUNT OFF" -W -h -1
    #Write-Host "Added icon image \\127.0.0.1\VISION\maps\icons\$iconFilename, ID $newImageID"
  
    # Icon (part 1)
    tsql "INSERT INTO $dbMo VALUES (20, $i, $newMapID, 'New generic button', 1, '', 0, 2)"
    $newMapObjectID = sqlcmd -S lpc:$pcName\SQLEXPRESS -d $($dbInfo.DatabaseName) -Q "SET NOCOUNT ON;SELECT TOP 1 ID FROM $dbMo WHERE selfuid = $i;SET NOCOUNT OFF" -W -h -1
    #Write-Host "Added icon object ID $newMapObjectID"
    
    # Icon (part 2)
    tsql "INSERT INTO $dbMoi VALUES ($newMapObjectID, 11, 11, 24, 24, NULL, NULL, $newImageID, NULL, NULL)"
    #Write-Host "Added icon object"
  
    $iconDest = "C:\Program Files (x86)\Titan\Vision Server\sites\default\maps\icons\$iconFilename"
    Copy-Item D:\icon1.png $iconDest
    #Write-Host "Copy map to $iconDest"
	
	$j = $j + 1
  } until ($j -gt $iconsPerMap)
  
  $i = $i + 1;
} until ($i -gt $mapLimit)