Param($versionToInstall, [switch]$uninstallVersions)
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

$programFilesParentFolder = $($localInfo.ProgramFilesParentFolder)
$programFilesFolderA = $($localInfo.ProgramFilesFolderA)
$programFilesFolderS = $($localInfo.ProgramFilesFolderS)
$programFilesFolderC = $($localInfo.ProgramFilesFolderC)
$programFilesFolderM = $($localInfo.ProgramFilesFolderM)

$flavours = $($localInfo.Flavours)
$flavourFolderNames = $($localInfo.FlavourFolderNames)
$selectedFlavour = $flavours[0]
$selectedFlavourFolderName = $flavourFolderNames[0]

if ($uninstallVersions) {
  if (Test-Path "C:\Program Files (x86)\$programFilesParentFolder\$programFilesFolderA\unins000.exe") {
    Write-Host "Uninstall $programTVA"
    & "C:\Program Files (x86)\$programFilesParentFolder\$programFilesFolderA\unins000.exe"
  }
  if (Test-Path "C:\Program Files (x86)\$programFilesParentFolder\$programFilesFolderS\unins000.exe") {
    Write-Host "Uninstall $programTVS"
    & "C:\Program Files (x86)\$programFilesParentFolder\$programFilesFolderS\unins000.exe"
  }
  if (Test-Path "C:\Program Files (x86)\$programFilesParentFolder\$programFilesFolderC\unins000.exe") {
    Write-Host "Uninstall $programTVC"
    & "C:\Program Files (x86)\$programFilesParentFolder\$programFilesFolderC\unins000.exe"
  }
  if (Test-Path "C:\Program Files (x86)\$programFilesParentFolder\$programFilesFolderM\unins000.exe") {
    Write-Host "Uninstall $programTVM"
    & "C:\Program Files (x86)\$programFilesParentFolder\$programFilesFolderM\unins000.exe"
  }
  
  Write-Host "Uninstall complete"
  return
}
return
# If no version specified then we list the versions
if (!$PSBoundParameters.ContainsKey('versionToInstall')) {
  $versionsToSort = @()
  $versionsX = Get-ChildItem "$galleryDir\$programTV\6*" | ForEach {
    $versionsToSort += New-Object PSObject -Property @{
    'Major' = 6
    'Minor' = $_.Name.split(".")[1]
    'MinorPL' = $_.Name.split(".")[1].PadLeft(5)
    }
  }

  $versionsAvail = $versionsToSort | Sort-Object Major, MinorPL -descending | Select-Object Major, Minor | Select-Object -first 20

  [int]$fileCount = 1
  foreach ($versionAvail in $versionsAvail) {
    $displayText = $fileCount.ToString().PadRight(4) + " " + $versionAvail.Major + "." + $versionAvail.Minor
    Write-Host $displayText
    $fileCount = $fileCount + 1
  }
  
  return
}

#$version = "6.37.1"
$version = $versionToInstall
$versionObject = New-Object PSObject -Property @{
  'Major' = $versionToInstall.split(".")[0]
  'Minor' = $versionToInstall.split(".")[1]
  'Revision' = $versionToInstall.split(".")[2]
}

# Create parent version folder
$versionSplit = $version.Split(".")
$parentVersion = $version.Replace($versionSplit[2], "x")

# Work up from 0 to n where n is the revision in the version - not all will be at that version
for($i=0; $i -le ($versionObject.Revision); $i++) {
  $versionText = $versionObject.Major + "." + $versionObject.Minor + "." + $i
  if (Test-Path "$galleryDir\$programTV\$parentVersion\$selectedFlavourFolderName\$programTVA\$versionText") {
    $versionA = $versionText
    if (!(Test-Path "$galleryDir\$programTV\$parentVersion\$selectedFlavourFolderName\$programTVA\$versionText\$programTVAExe")) {
	  Write-Host "$programTVAExe not found for $versionA"; return
	}
  }  
  if (Test-Path "$galleryDir\$programTV\$parentVersion\$selectedFlavourFolderName\$programTVS\$versionText") {
    $versionS = $versionText
    if (!(Test-Path "$galleryDir\$programTV\$parentVersion\$selectedFlavourFolderName\$programTVS\$versionText\$programTVSExe")) {
	  Write-Host "$programTVSExe not found for $versionS"; return
	}
  }
  if (Test-Path "$galleryDir\$programTV\$parentVersion\$selectedFlavourFolderName\$programTVC\$versionText") {
    $versionC = $versionText
    if (!(Test-Path "$galleryDir\$programTV\$parentVersion\$selectedFlavourFolderName\$programTVC\$versionText\$programTVCExe")) {
	  Write-Host "$programTVCExe not found for $versionC"; return
	}
  }
  if (Test-Path "$galleryDir\$programTV\$parentVersion\$selectedFlavourFolderName\$programTVM\$versionText") {
    $versionM = $versionText
    if (!(Test-Path "$galleryDir\$programTV\$parentVersion\$selectedFlavourFolderName\$programTVM\$versionText\$programTVMExe")) {
	  Write-Host "$programTVMExe not found for $versionM"; return
	}
  }
}

Write-Host "Version detection is as follows: `n"
Write-Host "$programTVA $versionA" 
Write-Host "$programTVS $versionS" 
Write-Host "$programTVC $versionC" 
Write-Host "$programTVM $versionM"

$confirmation = Read-Host "Do you want to install these versions? (y/n)"
if ($confirmation -Match 'n') {
  return
}

Write-Host "Installing $selectedFlavour $programTVA $versionA"
& "$galleryDir\$programTV\$parentVersion\$selectedFlavourFolderName\$programTVA\$versionA\$programTVAExe" /silent /suppressmsgboxes | Out-Null
if ($LastExitCode -ne 0) { Write-Host "Error"; return}
Write-Host "Installing $selectedFlavour $programTVS $versionS"
& "$galleryDir\$programTV\$parentVersion\$selectedFlavourFolderName\$programTVS\$versionS\$programTVSExe" /silent /suppressmsgboxes | Out-Null
if ($LastExitCode -ne 0) { Write-Host "Error"; return}
Write-Host "Installing $selectedFlavour $programTVC $versionC"
& "$galleryDir\$programTV\$parentVersion\$selectedFlavourFolderName\$programTVC\$versionC\$programTVCExe" /silent /suppressmsgboxes | Out-Null
if ($LastExitCode -ne 0) { Write-Host "Error"; return}
Write-Host "Installing $selectedFlavour $programTVM $versionM"
& "$galleryDir\$programTV\$parentVersion\$selectedFlavourFolderName\$programTVM\$versionM\$programTVMExe" /silent /suppressmsgboxes | Out-Null
if ($LastExitCode -ne 0) { Write-Host "Error"; return}