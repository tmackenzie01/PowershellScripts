# Scan gallery (add -TestGallery switch later)
# Scan versions

# if version not supplied then prompt (last 10 versions)
# if version supplied then confirm it exists, if not re-promt

# Scan version flavours
# Prompt for flavours
# Install

# Load data
Write-Host "Loading data..."
if (([System.IO.Directory]::Exists("$powershellIncludeDirectory"))) {
  # Load db info
  # To access properties of $ localInfo when inside a string use "$($localInfo.DatabaseName)"
  # For some reason I can't get this to work inside a sqlcmd call so have to
  # use messy alias variables like in Tsql-List-Databases
  if (([System.IO.File]::Exists("$powershellIncludeDirectory\LocalInfo.json"))) {
    $dbInfoJson = Get-Content "$powershellIncludeDirectory\LocalInfo.json"
    $jsonSerializer = New-Object System.Web.Script.Serialization.JavaScriptSerializer
    $localInfo = $jsonSerializer.DeserializeObject($dbInfoJson)
  }
  else {
    Write-Host "Local info not found"
  }
}

$galleryDir = $($localInfo.GalleryDir)
$programTV = $($localInfo.ProgramTV)
$programTVA = $($localInfo.ProgramTVA)
$programTVS = $($localInfo.ProgramTVS)
$programTVC = $($localInfo.ProgramTVC)
$programTVM = $($localInfo.ProgramTVM)
$programTVAExe = $($localInfo.ProgramTVAExe)
$programTVSExe = $($localInfo.ProgramTVSExe)
$programTVCExe = $($localInfo.ProgramTVCExe)
$programTVMExe = $($localInfo.ProgramTVMExe)
$flavours = $($localInfo.Flavours)
$flavourFolderNames = $($localInfo.FlavourFolderNames)
$selectedFlavour = $flavours[0]
$selectedFlavourFolderName = $flavourFolderNames[0]

$version = "6.37.1"

$versionA = $version
$versionS = $version
$versionC = $version
$versionM = $version

# Create parent version folder
$versionSplit = $version.Split(".")
$parentVersion = $version.Replace($versionSplit[2], "x")

Write-Host "Installing $selectedFlavour $programTVA $versionA"
& "$galleryDir\$programTV\$parentVersion\$selectedFlavourFolderName\$programTVA\$versionA\$programTVAExe" /silent /suppressmsgboxes | Out-Null
Write-Host "Installing $selectedFlavour $programTVS $versionS"
& "$galleryDir\$programTV\$parentVersion\$selectedFlavourFolderName\$programTVS\$versionS\$programTVSExe" /silent /suppressmsgboxes | Out-Null
Write-Host "Installing $selectedFlavour $programTVC $versionC"
& "$galleryDir\$programTV\$parentVersion\$selectedFlavourFolderName\$programTVC\$versionC\$programTVCExe" /silent /suppressmsgboxes | Out-Null
Write-Host "Installing $selectedFlavour $programTVM $versionM"
& "$galleryDir\$programTV\$parentVersion\$selectedFlavourFolderName\$programTVM\$versionM\$programTVMExe" /silent /suppressmsgboxes | Out-Null
