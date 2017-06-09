<#
.SYNOPSIS
Installs/uninstalls programs from official Gallery & TestGallery

.EXAMPLE
./InstallSetups.ps1 6.37
Installs 6.37 from the official Gallery (will find the latest 6.37.x version for each component) and then prompt which component you want installed

.EXAMPLE
./InstallSetups.ps1 -uninstallVersions
Uninstalls all versions of installed programs

.LINK
http://github.com/tmackenzie01/PowershellScripts
#>

Param($versionToInstall, [switch]$uninstallVersions, [switch]$testGallery, [switch]$testGallery7, $flavour)

# Functionality to add
#   Flavour selection
#   Selection of listed versions in TestGallery
#   Listing of 7 versions in Gallery

# Load data
Write-Host "Loading data..."
if (([System.IO.Directory]::Exists("$powershellIncludeDirectory"))) {
  # Load local info
  # To access properties of $ localInfo when inside a string use "$($localInfo.DatabaseName)"
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
$testGalleryDir = $($localInfo.TestGalleryDir)
$programTV = $($localInfo.ProgramTV)
# Could put all these into arrays for A,S,C,M - but don't want to overcompliate things at the moment - maybe later
$programTVA = $($localInfo.ProgramTVA)
$programTVS = $($localInfo.ProgramTVS)
$programTVC = $($localInfo.ProgramTVC)
$programTVM = $($localInfo.ProgramTVM)
$programTVAExe = $($localInfo.ProgramTVAExe)
$programTVAOLdExe = $($localInfo.ProgramTVAOldExe)
$programTVSExe = $($localInfo.ProgramTVSExe)
$programTVCExe = $($localInfo.ProgramTVCExe)
$programTVMExe = $($localInfo.ProgramTVMExe)

$programFilesParentFolder = $($localInfo.ProgramFilesParentFolder)
$programFilesFolderA = $($localInfo.ProgramFilesFolderA)
$programFilesFolderS = $($localInfo.ProgramFilesFolderS)
$programFilesFolderC = $($localInfo.ProgramFilesFolderC)
$programFilesFolderM = $($localInfo.ProgramFilesFolderM)
$programFilesFolderC7 = $($localInfo.ProgramFilesFolderC7)
$programFilesFolderM7 = $($localInfo.ProgramFilesFolderM7)

$flavours = $($localInfo.Flavours)
$flavourFolderNames = $($localInfo.FlavourFolderNames)

$installA = $false
$installS = $false
$installC = $false
$installM = $false

$flavourIndex = 0
$matchFound = $false
if ($PSBoundParameters.ContainsKey('flavour')) {
  $specifiedFlavour = $flavour
  for($i=0; $i -lt $flavours.Count; $i++) {
    $flavourToCheck = $flavours[$i];
    if (($specifiedFlavour -eq $flavourToCheck) -or ($specifiedFlavour -eq $flavourToCheck.Replace(" ", ""))) {
      $flavourIndex = $i
	  $matchFound = $true
	  Write-Host "Installing programs for specified flavour - $specifiedFlavour"
	}
  }

  if (!$matchFound) {
    Write-Host "Could not find specified flavour - $specifiedFlavour"
	return
  }
}

$selectedFlavour = $flavours[$flavourIndex]
$selectedFlavourFolderName = $flavourFolderNames[$flavourIndex] + "\"

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
  $programTVC7 = $programTVC + "7"
  if (Test-Path "C:\Program Files (x86)\$programFilesParentFolder\$programFilesFolderC7\unins000.exe") {
    Write-Host "Uninstall $programTVC7"
    & "C:\Program Files (x86)\$programFilesParentFolder\$programFilesFolderC7\unins000.exe"
  }
  if (Test-Path "C:\Program Files (x86)\$programFilesParentFolder\$programFilesFolderM\unins000.exe") {
    Write-Host "Uninstall $programTVM"
    & "C:\Program Files (x86)\$programFilesParentFolder\$programFilesFolderM\unins000.exe"
  }
  $programTVM7 = $programTVM + "7"
  Write-Host "C:\Program Files (x86)\$programFilesParentFolder\$programFilesFolderM7\unins000.exe"
  if (Test-Path "C:\Program Files (x86)\$programFilesParentFolder\$programFilesFolderM7\unins000.exe") {
    Write-Host "Uninstall $programTVM7"
    & "C:\Program Files (x86)\$programFilesParentFolder\$programFilesFolderM7\unins000.exe"
  }
  
  Write-Host "Uninstall complete"
  return
}

# Skip this part for the testGallery switch for now

# If no version specified then we list the versions
if ((!$PSBoundParameters.ContainsKey('versionToInstall')) -and (!$PSBoundParameters.ContainsKey('testGallery')) -and (!$PSBoundParameters.ContainsKey('testGallery7'))) {
  $versionXobjs = @()
  $versionsX = Get-ChildItem "$galleryDir\$programTV\6*" | ForEach {
    $versionXobjs += New-Object PSObject -Property @{
    'Major' = 6
    'Minor' = $_.Name.split(".")[1]
    'MinorPL' = $_.Name.split(".")[1].PadLeft(5)
    }
  }
  
  $versionActualobjs = @()
  foreach ($versionX in $versionXobjs) {
    $parentVersion = $versionX.Major.toString() + "." + $versionX.Minor.toString() + ".x" + "\"
	
	# ?{ $_.PSIsContainer } gets directories only
	if (Test-Path "$galleryDir\$programTV\$parentVersion$selectedFlavourFolderName$programTVA") {
      $versionsActual = Get-ChildItem "$galleryDir\$programTV\$parentVersion$selectedFlavourFolderName$programTVA" | ?{ $_.PSIsContainer } | ForEach {
        $versionActualobjs += New-Object PSObject -Property @{
          'Major' = 6
          'Minor' = $_.Name.split(".")[1]
          'MinorPL' = $_.Name.split(".")[1].PadLeft(5)
          'Revision' = $_.Name.split(".")[2]
          'RevisionPL' = $_.Name.split(".")[2].PadLeft(5)
		}
	  }
    }
	if (Test-Path "$galleryDir\$programTV\$parentVersion$selectedFlavourFolderName$programTVS") {
      $versionsActual = Get-ChildItem "$galleryDir\$programTV\$parentVersion$selectedFlavourFolderName$programTVS" | ?{ $_.PSIsContainer } | ForEach {
        $versionActualobjs += New-Object PSObject -Property @{
          'Major' = 6
          'Minor' = $_.Name.split(".")[1]
          'MinorPL' = $_.Name.split(".")[1].PadLeft(5)
          'Revision' = $_.Name.split(".")[2]
          'RevisionPL' = $_.Name.split(".")[2].PadLeft(5)
		}
	  }
    }
	if (Test-Path "$galleryDir\$programTV\$parentVersion$selectedFlavourFolderName$programTVS") {
      $versionsActual = Get-ChildItem "$galleryDir\$programTV\$parentVersion$selectedFlavourFolderName$programTVC" | ?{ $_.PSIsContainer } | ForEach {
        $versionActualobjs += New-Object PSObject -Property @{
          'Major' = 6
          'Minor' = $_.Name.split(".")[1]
          'MinorPL' = $_.Name.split(".")[1].PadLeft(5)
          'Revision' = $_.Name.split(".")[2]
          'RevisionPL' = $_.Name.split(".")[2].PadLeft(5)
		}
	  }
    }
	if (Test-Path "$galleryDir\$programTV\$parentVersion$selectedFlavourFolderName$programTVS") {
      $versionsActual = Get-ChildItem "$galleryDir\$programTV\$parentVersion$selectedFlavourFolderName$programTVM" | ?{ $_.PSIsContainer } | ForEach {
        $versionActualobjs += New-Object PSObject -Property @{
          'Major' = 6
          'Minor' = $_.Name.split(".")[1]
          'MinorPL' = $_.Name.split(".")[1].PadLeft(5)
          'Revision' = $_.Name.split(".")[2]
          'RevisionPL' = $_.Name.split(".")[2].PadLeft(5)
		}
	  }
    }
  }  
  
  $versionsAvail = $versionActualobjs | Sort-Object Major, MinorPL, RevisionPL -descending -unique | Select-Object Major, Minor, Revision -first 30

  [int]$fileCount = 1
  foreach ($versionAvail in $versionsAvail) {
    $displayText = $fileCount.ToString().PadRight(4) + " " + $versionAvail.Major + "." + $versionAvail.Minor + "." + $versionAvail.Revision
    Write-Host $displayText
    $fileCount = $fileCount + 1
  }
  
  $selection = Read-Host "Enter a single number for the version you wish to install"
  $versionToInstall = $versionsAvail[$selection-1].Major.toString() + "." + $versionsAvail[$selection-1].Minor.toString() + "." + $versionsAvail[$selection-1].Revision.toString()
}

if (($testGallery) -or ($testGallery7)) {
  $galleryDir = $testGalleryDir
  $parentVersion = ""
  
  if ($testGallery) {
    $versionA = Get-ChildItem "$galleryDir\$programTV\$parentVersion$selectedFlavourFolderName$programTVA" | Where-Object { (($_.Name -like "2017*") -and !($_.Name -like "*_7")) } | Sort-Object -descending | Select-Object Name -first 1
    $versionA = $versionA.Name
    $versionS = Get-ChildItem "$galleryDir\$programTV\$parentVersion$selectedFlavourFolderName$programTVS" | Where-Object { (($_.Name -like "2017*") -and !($_.Name -like "*_7")) } | Sort-Object -descending | Select-Object Name -first 1
    $versionS = $versionS.Name
    $versionC = Get-ChildItem "$galleryDir\$programTV\$parentVersion$selectedFlavourFolderName$programTVC" | Where-Object { (($_.Name -like "2017*") -and !($_.Name -like "*_7")) } | Sort-Object -descending | Select-Object Name -first 1
    $versionC = $versionC.Name
    $versionM = Get-ChildItem "$galleryDir\$programTV\$parentVersion$selectedFlavourFolderName$programTVM" | Where-Object { (($_.Name -like "2017*") -and !($_.Name -like "*_7")) } | Sort-Object -descending | Select-Object Name -first 1
    $versionM = $versionM.Name
  } else {
    $programTVC = "$programTVC" + "7"
    $programTVM = "$programTVM" + "7"
    $versionA = Get-ChildItem "$galleryDir\$programTV\$parentVersion$selectedFlavourFolderName$programTVA" | Where-Object { (($_.Name -like "2017*") -and ($_.Name -like "*_7")) } | Sort-Object -descending | Select-Object Name -first 1
    $versionA = $versionA.Name
    $versionS = Get-ChildItem "$galleryDir\$programTV\$parentVersion$selectedFlavourFolderName$programTVS" | Where-Object { (($_.Name -like "2017*") -and ($_.Name -like "*_7")) } | Sort-Object -descending | Select-Object Name -first 1
    $versionS = $versionS.Name
    $versionC = Get-ChildItem "$galleryDir\$programTV\$parentVersion$selectedFlavourFolderName$programTVC" | Where-Object { $_.Name -like "2017*" } | Sort-Object -descending | Select-Object Name -first 1
    $versionC = $versionC.Name
    $versionM = Get-ChildItem "$galleryDir\$programTV\$parentVersion$selectedFlavourFolderName$programTVM" | Where-Object { $_.Name -like "2017*" } | Sort-Object -descending | Select-Object Name -first 1
    $versionM = $versionM.Name  
  }
} else
{
  $versionObject = New-Object PSObject -Property @{
    'Major' = $versionToInstall.split(".")[0]
    'Minor' = $versionToInstall.split(".")[1]
    'Revision' = $versionToInstall.split(".")[2]
  }

  # Create parent version folder
  $parentVersion = $versionObject.Major + "." + $versionObject.Minor + ".x" + "\"

  # Check versions supports flavours (started 6.17)
  # This check doesn't work for single digit minor comparing to double digit minot (17)
  if (($versionObject.Major -le 6) -and ($versionObject.Minor -lt 17)) {
    $selectedFlavourFolderName = "" # clear the flavour sub-folder
  }
  # Check versions supports flavours (started 6.17)
  # This check doesn't work for single digit minor comparing to double digit minot (21)
  if (($versionObject.Major -le 6) -and ($versionObject.Minor -lt 21)) {
    $programTVAExe = $programTVAOldExe
  }

  # Work up from 0 to n where n is the revision in the version - not all will be at that version
  for($i=0; $i -le ($versionObject.Revision); $i++) {
    $versionText = $versionObject.Major + "." + $versionObject.Minor + "." + $i
    if (Test-Path "$galleryDir\$programTV\$parentVersion$selectedFlavourFolderName$programTVA\$versionText") {
      $versionA = $versionText
      if (!(Test-Path "$galleryDir\$programTV\$parentVersion$selectedFlavourFolderName$programTVA\$versionText\$programTVAExe")) {
	    Write-Host "$programTVAExe not found for $versionA"; return
	  }
    }  
    if (Test-Path "$galleryDir\$programTV\$parentVersion$selectedFlavourFolderName$programTVS\$versionText") {
      $versionS = $versionText
      if (!(Test-Path "$galleryDir\$programTV\$parentVersion$selectedFlavourFolderName$programTVS\$versionText\$programTVSExe")) {
	    Write-Host "$programTVSExe not found for $versionS"; return
  	  }
    }
    if (Test-Path "$galleryDir\$programTV\$parentVersion$selectedFlavourFolderName$programTVC\$versionText") {
      $versionC = $versionText
      if (!(Test-Path "$galleryDir\$programTV\$parentVersion$selectedFlavourFolderName$programTVC\$versionText\$programTVCExe")) {
	    Write-Host "$programTVCExe not found for $versionC"; return
	  }
    }
    if (Test-Path "$galleryDir\$programTV\$parentVersion$selectedFlavourFolderName$programTVM\$versionText") {
      $versionM = $versionText
      if (!(Test-Path "$galleryDir\$programTV\$parentVersion$selectedFlavourFolderName$programTVM\$versionText\$programTVMExe")) {
	    Write-Host "$programTVMExe not found for $versionM"; return
      }
    }
  }
}

Write-Host "Version detection is as follows: `n"
Write-Host "$programTVA $versionA" 
Write-Host "$programTVS $versionS" 
Write-Host "$programTVC $versionC" 
Write-Host "$programTVM $versionM"

$confirmation = Read-Host "Do you want to install these versions? (y/n) Or a selection (s)"
if ($confirmation -Match 'n') {
  return
} else {
  if ($confirmation -Match 's') {
	Write-Host "`n1   Admin"
	Write-Host "2   Server"
	Write-Host "3   Client"
	Write-Host "4   Multiplexer"
    $selection = Read-Host "Enter a single number or CSV list of numbers for the programs you wish to install"
	foreach($singleSelection in $selection.split(",")) {
	  if ($singleSelection.trim() -eq 1) { $installA = $true }
	  if ($singleSelection.trim() -eq 2) { $installS = $true }
	  if ($singleSelection.trim() -eq 3) { $installC = $true }
	  if ($singleSelection.trim() -eq 4) { $installM = $true }
	}
  } else {
    $installA = $true
    $installS = $true
    $installC = $true
    $installM = $true
  }
}

if ($installA -eq $true) {
  Write-Host "Installing $selectedFlavour $programTVA $versionA"
  & "$galleryDir\$programTV\$parentVersion$selectedFlavourFolderName$programTVA\$versionA\$programTVAExe" /silent /suppressmsgboxes | Out-Null
  if ($LastExitCode -ne 0) { Write-Host "Error"; return}
}
if ($installS -eq $true) {
  Write-Host "Installing $selectedFlavour $programTVS $versionS"
  & "$galleryDir\$programTV\$parentVersion$selectedFlavourFolderName$programTVS\$versionS\$programTVSExe" /silent /suppressmsgboxes | Out-Null
  if ($LastExitCode -ne 0) { Write-Host "Error"; return}
}
if ($installC -eq $true) {
  Write-Host "Installing $selectedFlavour $programTVC $versionC"
  & "$galleryDir\$programTV\$parentVersion$selectedFlavourFolderName$programTVC\$versionC\$programTVCExe" /silent /suppressmsgboxes | Out-Null
  if ($LastExitCode -ne 0) { Write-Host "Error"; return}
}
  if ($installM -eq $true) {
  Write-Host "Installing $selectedFlavour $programTVM $versionM" 
  & "$galleryDir\$programTV\$parentVersion$selectedFlavourFolderName$programTVM\$versionM\$programTVMExe" /silent /suppressmsgboxes | Out-Null
  if ($LastExitCode -ne 0) { Write-Host "Error"; return}
}