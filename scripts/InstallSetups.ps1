


<#
.SYNOPSIS
Installs/uninstalls programs from official Gallery & TestGallery

.EXAMPLE
./InstallSetups.ps1
Will list most recent 20 versions in Gallery

.EXAMPLE
./InstallSetups.ps1 -testGallery
Will list most recent 20 versions in Test Gallery

.EXAMPLE
./InstallSetups.ps1 6.37
Installs 6.37 from the official Gallery (will find the latest 6.37.x version for each component) and then prompt which component you want installed

.EXAMPLE
./InstallSetups.ps1 -uninstallVersions
Uninstalls all versions of installed programs

.EXAMPLE
./InstallSetups.ps1 -flavour <Flavourname>
Allows specification of flavour, can be in quotes with spaces, or no quotes and no spaces

.LINK
http://github.com/tmackenzie01/PowershellScripts
#>

Param($versionToInstall, [switch]$uninstallVersions, [switch]$gallery7, [switch]$testGallery, [switch]$testGallery7, [switch]$galleryRFS, [switch]$galleryRecorder, $flavour, $platform)

# Functionality to add
#   Flavour selection
#   Selection of listed versions in TestGallery
#   Listing of 7 versions in Gallery

function IsProcessRunning($processName) {
  # Check if program is running
  $process = Get-Process | Where-Object { $_.Name -eq "$processName" }
  if ($process.Name -ne "$processName") {
    return $false
  } else {
    "$processName already running"
    return $true
  }
}

function StopAndRemoveRunningService($serviceProgram) {
  Write-Host "Stop $serviceProgram (if installed)"
  Stop-Service "$serviceProgram" -ErrorAction "SilentlyContinue"
  Write-Host "Set $serviceProgram to manual start (if installed)"
  Set-Service "$serviceProgram" -startuptype "manual" -ErrorAction "SilentlyContinue"
  $serv = Get-Service "$serviceProgram" -ErrorAction "SilentlyContinue"
  if ($serv -ne $null) {
    sc.exe delete "$serviceProgram"
  }
}

# Load data
"Loading data..."
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
$programR = $($localInfo.ProgramR)
$programRFS = $($localInfo.ProgramRFS)
# Could put all these into arrays for A,S,C,M - but don't want to overcompliate things at the moment - maybe later
$programTVA = $($localInfo.ProgramTVA)
$programTVS = $($localInfo.ProgramTVS)
$programTVC = $($localInfo.ProgramTVC)
$programTVM = $($localInfo.ProgramTVM)
$programR = $($localInfo.ProgramR)
$programRFS = $($localInfo.ProgramRFS)

$programTVAExe = $($localInfo.ProgramTVAExe)
$programTVAOLdExe = $($localInfo.ProgramTVAOldExe)
$programTVSExe = $($localInfo.ProgramTVSExe)
$programTVCExe = $($localInfo.ProgramTVCExe)
$programTVMExe = $($localInfo.ProgramTVMExe)
$programRExe = $($localInfo.ProgramRExe)
$programRFSExe = $($localInfo.ProgramRFSExe)

$processTVAName = $($localInfo.ProcessTVAName)
$processTVSName = $($localInfo.ProcessTVSName)
$processTVCName = $($localInfo.ProcessTVCName)
$processTVMName = $($localInfo.ProcessTVMName)

$programRInstallExe = $($localInfo.ProgramRInstallExe)

$serviceProgramTVS = $($localInfo.ServiceProgramTVS)
$serviceProgramTVR = $($localInfo.ServiceProgramTVR)

$programFilesParentFolder = $($localInfo.ProgramFilesParentFolder)
$programFilesFolderA = $($localInfo.ProgramFilesFolderA)
$programFilesFolderS = $($localInfo.ProgramFilesFolderS)
$programFilesFolderC = $($localInfo.ProgramFilesFolderC)
$programFilesFolderM = $($localInfo.ProgramFilesFolderM)
$programFilesFolderR = $($localInfo.ProgramFilesFolderR)
$programFilesFolderRFS = $($localInfo.ProgramFilesFolderRFS)
$programFilesFolderC7 = $($localInfo.ProgramFilesFolderC7)
$programFilesFolderM7 = $($localInfo.ProgramFilesFolderM7)

$flavours = $($localInfo.Flavours)
$flavourFolderNames = $($localInfo.FlavourFolderNames)

$installA = $false
$installS = $false
$installC = $false
$installM = $false
$installR = $false
$installRFS = $false

$selectedPlatform = "x86"
if ($PSBoundParameters.ContainsKey('platform')) {
  $selectedPlatform = "$platform"
}

$galleryDir = $galleryDir + "\$selectedPlatform"
$testGalleryDir = $testGalleryDir + "\$selectedPlatform"

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
$releaseFolderName = "Release\" # for RFS

if ($uninstallVersions) {
  # Admin x86
  if (Test-Path "C:\Program Files (x86)\$programFilesParentFolder\$programFilesFolderA\unins000.exe") {
    if (!(IsProcessRunning($processTVAName))) {
      Write-Host "Uninstall $programTVA (x86)"
      & "C:\Program Files (x86)\$programFilesParentFolder\$programFilesFolderA\unins000.exe"
	}
  }
  # Admin x64
  if (Test-Path "C:\Program Files\$programFilesParentFolder\$programFilesFolderA\unins000.exe") {
    if (!(IsProcessRunning($processTVAName))) {
      Write-Host "Uninstall $programTVA (x64)"
      & "C:\Program Files\$programFilesParentFolder\$programFilesFolderA\unins000.exe"
    }
  }
  # Server x86
  if (Test-Path "C:\Program Files (x86)\$programFilesParentFolder\$programFilesFolderS\unins000.exe") {
    StopAndRemoveRunningService($serviceProgramTVS)
    if (!(IsProcessRunning($processTVSName))) {
      Write-Host "Uninstall $programTVS"
      & "C:\Program Files (x86)\$programFilesParentFolder\$programFilesFolderS\unins000.exe"
    }
  }
  # Server x64
  if (Test-Path "C:\Program Files\$programFilesParentFolder\$programFilesFolderS\unins000.exe") {
    StopAndRemoveRunningService($serviceProgramTVS)
    if (!(IsProcessRunning($processTVSName))) {
      Write-Host "Uninstall $programTVS (x64)"
      & "C:\Program Files\$programFilesParentFolder\$programFilesFolderS\unins000.exe"
    }
  }
  # Client x86
  if (Test-Path "C:\Program Files (x86)\$programFilesParentFolder\$programFilesFolderC\unins000.exe") {
    if (!(IsProcessRunning($processTVCName))) {
      Write-Host "Uninstall $programTVC (x86)"
      & "C:\Program Files (x86)\$programFilesParentFolder\$programFilesFolderC\unins000.exe"
    }
  }
  # Client x64
  if (Test-Path "C:\Program Files\$programFilesParentFolder\$programFilesFolderC\unins000.exe") {
    if (!(IsProcessRunning($processTVCName))) {
      Write-Host "Uninstall $programTVC (x64)"
      & "C:\Program Files\$programFilesParentFolder\$programFilesFolderC\unins000.exe"
    }
  }
  $programTVC7 = $programTVC + "7"
  # Client7 x86
  if (Test-Path "C:\Program Files (x86)\$programFilesParentFolder\$programFilesFolderC7\unins000.exe") {
    if (!(IsProcessRunning($processTVCName))) {
      Write-Host "Uninstall $programTVC7 (x86)"
      & "C:\Program Files (x86)\$programFilesParentFolder\$programFilesFolderC7\unins000.exe"
    }
  }
  # Client7 x64
  if (Test-Path "C:\Program Files\$programFilesParentFolder\$programFilesFolderC7\unins000.exe") {
    if (!(IsProcessRunning($processTVCName))) {
      Write-Host "Uninstall $programTVC7 (x64)"
      & "C:\Program Files\$programFilesParentFolder\$programFilesFolderC7\unins000.exe"
    }
  }
  # Multiplexer x86
  if (Test-Path "C:\Program Files (x86)\$programFilesParentFolder\$programFilesFolderM\unins000.exe") {
    if (!(IsProcessRunning($processTVMName))) {
      Write-Host "Uninstall $programTVM (x86)"
      & "C:\Program Files (x86)\$programFilesParentFolder\$programFilesFolderM\unins000.exe"
    }
  }
  # Multiplexer x64
  if (Test-Path "C:\Program Files\$programFilesParentFolder\$programFilesFolderM\unins000.exe") {
    if (!(IsProcessRunning($processTVMName))) {
      Write-Host "Uninstall $programTVM (x64)"
      & "C:\Program Files (x86)\$programFilesParentFolder\$programFilesFolderM\unins000.exe"
    }
  }
  $programTVM7 = $programTVM + "7"
  # Multiplexer7 x86
  if (Test-Path "C:\Program Files (x86)\$programFilesParentFolder\$programFilesFolderM7\unins000.exe") {
    if (!(IsProcessRunning($processTVMName))) {
      Write-Host "Uninstall $programTVM7 (x86)"
      & "C:\Program Files (x86)\$programFilesParentFolder\$programFilesFolderM7\unins000.exe"
    }
  }
  # Multiplexer7 x64
  if (Test-Path "C:\Program Files\$programFilesParentFolder\$programFilesFolderM7\unins000.exe") {
    if (!(IsProcessRunning($processTVMName))) {
      Write-Host "Uninstall $programTVM7 (x64)"
      & "C:\Program Files\$programFilesParentFolder\$programFilesFolderM7\unins000.exe"
    }
  }

  # Recorder x86
  if (Test-Path "C:\Program Files (x86)\$programFilesParentFolder\$programFilesFolderR\unins000.exe") {
    StopAndRemoveRunningService($serviceProgramTVR)
    if (!(IsProcessRunning($processTVRName))) {
      Write-Host "Uninstall $programR (x86)"
      & "C:\Program Files (x86)\$programFilesParentFolder\$programFilesFolderR\unins000.exe"
    }
  }
  # Recorder x64
  if (Test-Path "C:\Program Files\$programFilesParentFolder\$programFilesFolderR\unins000.exe") {
    StopAndRemoveRunningService($serviceProgramTVR)
    if (!(IsProcessRunning($processTVRName))) {
      Write-Host "Uninstall $programR (x64)"
      & "C:\Program Files\$programFilesParentFolder\$programFilesFolderR\unins000.exe"
    }
  }

  # RFS x86
  if (Test-Path "C:\Program Files (x86)\$programFilesParentFolder\$programFilesFolderRFS\unins000.exe") {
    Write-Host "Uninstall $programRFS (x86)"
    & "C:\Program Files (x86)\$programFilesParentFolder\$programFilesFolderRFS\unins000.exe"
  }
  # RFS x64
  if (Test-Path "C:\Program Files\$programFilesParentFolder\$programFilesFolderRFS\unins000.exe") {
    Write-Host "Uninstall $programRFS (x64)"
    & "C:\Program Files\$programFilesParentFolder\$programFilesFolderRFS\unins000.exe"
  }

  Write-Host "Uninstall complete"
  return
}

# Skip this part for the testGallery switch for now

$searchVersion = 6
if ($gallery7) {
  $searchVersion = 7
  $programTVM = $programTVM + "7"
  $programTVC = $programTVC + "7"
}

# If no version specified then we list the versions
if (!$PSBoundParameters.ContainsKey('versionToInstall')) {
  $versionXobjs = @()
  $nonTestGallerySearch = $false
  
  if ($PSBoundParameters.ContainsKey('galleryRFS')) {
    $searchGalleryDir = "$galleryDir\$programRFS\2.6.x\*"
    $nonTestGallerySearch = $true
  } else {
    if ($PSBoundParameters.ContainsKey('galleryRecorder')) {
      $searchGalleryDir = "$galleryDir\$ProgramR\1.12*"
      $nonTestGallerySearch = $true
    } else {
      if ((!$PSBoundParameters.ContainsKey('testGallery')) -and (!$PSBoundParameters.ContainsKey('testGallery7'))) {
        $searchGalleryDir = "$galleryDir\$programTV\$searchVersion*"
        $nonTestGallerySearch = $true
      }
    }
  }
  
  if ($nonTestGallerySearch) {
    $versionsX = Get-ChildItem $searchGalleryDir | ForEach {
    $versionXobjs += New-Object PSObject -Property @{
      'Major' = $_.Name.split(".")[0]
      'Minor' = $_.Name.split(".")[1]
      'MinorPL' = $_.Name.split(".")[1].PadLeft(5)
      }
    }
  
    # With galleryRFS switch on we do this next part, but it will get no results
    $versionActualobjs = @()
    foreach ($versionX in $versionXobjs) {
      $parentVersion = $versionX.Major.toString() + "." + $versionX.Minor.toString() + ".x" + "\"
	
      # ?{ $_.PSIsContainer } gets directories only
  	  if (Test-Path "$galleryDir\$programTV\$parentVersion$selectedFlavourFolderName$programTVA") {
        $versionsActual = Get-ChildItem "$galleryDir\$programTV\$parentVersion$selectedFlavourFolderName$programTVA" | ?{ $_.PSIsContainer } | ForEach {
          $versionActualobjs += New-Object PSObject -Property @{
            'Major' = $searchVersion
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
            'Major' = $searchVersion
            'Minor' = $_.Name.split(".")[1]
            'MinorPL' = $_.Name.split(".")[1].PadLeft(5)
            'Revision' = $_.Name.split(".")[2]
            'RevisionPL' = $_.Name.split(".")[2].PadLeft(5)
		  }
	    }
      }
	  if (Test-Path "$galleryDir\$programTV\$parentVersion$selectedFlavourFolderName$programTVC") {
        $versionsActual = Get-ChildItem "$galleryDir\$programTV\$parentVersion$selectedFlavourFolderName$programTVC" | ?{ $_.PSIsContainer } | ForEach {
          $versionActualobjs += New-Object PSObject -Property @{
            'Major' = $searchVersion
            'Minor' = $_.Name.split(".")[1]
            'MinorPL' = $_.Name.split(".")[1].PadLeft(5)
            'Revision' = $_.Name.split(".")[2]
            'RevisionPL' = $_.Name.split(".")[2].PadLeft(5)
		  }
	    }
      }
	  if (Test-Path "$galleryDir\$programTV\$parentVersion$selectedFlavourFolderName$programTVM") {
        $versionsActual = Get-ChildItem "$galleryDir\$programTV\$parentVersion$selectedFlavourFolderName$programTVM" | ?{ $_.PSIsContainer } | ForEach {
          $versionActualobjs += New-Object PSObject -Property @{
            'Major' = $searchVersion
            'Minor' = $_.Name.split(".")[1]
            'MinorPL' = $_.Name.split(".")[1].PadLeft(5)
            'Revision' = $_.Name.split(".")[2]
            'RevisionPL' = $_.Name.split(".")[2].PadLeft(5)
		  }
	    }
      }
	
	  # RFS slightly different
	  if (Test-Path "$galleryDir\$programRFS\$parentVersion") {
        $versionsActual = Get-ChildItem "$galleryDir\$programRFS\$parentVersion" | ?{ $_.PSIsContainer } | ForEach {
          $versionActualobjs += New-Object PSObject -Property @{
            'Major' = $_.Name.split(".")[0]
            'Minor' = $_.Name.split(".")[1]
            'MinorPL' = $_.Name.split(".")[1].PadLeft(5)
            'Revision' = $_.Name.split(".")[2]
            'RevisionPL' = $_.Name.split(".")[2].PadLeft(5)
		  }
	    }
      }

	  # Recorder slightly different again
	  if (Test-Path "$galleryDir\$programR\$parentVersion") {
        $versionsActual = Get-ChildItem "$galleryDir\$programR\$parentVersion$selectedFlavourFolderName" | ?{ $_.PSIsContainer } | ForEach {
          $versionActualobjs += New-Object PSObject -Property @{
            'Major' = $_.Name.split(".")[0]
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
  
    if ($fileCount -eq 1) {
      "No versions found"
	  return
    } else {  
      $selection = Read-Host "Enter a single number for the version you wish to install"

      # Clear all the read prompt response for this script - do it here in case we exit the script early
      Clear-History -Command "Read-Host"

      $versionToInstall = $versionsAvail[$selection-1].Major.toString() + "." + $versionsAvail[$selection-1].Minor.toString() + "." + $versionsAvail[$selection-1].Revision.toString()
    }
  }
}

if (($testGallery) -or ($testGallery7)) {
  $galleryDir = $testGalleryDir
  $parentVersion = ""
  
  # We are always getting just the latest testtag from the TestGallery so it will always have x86/x64 exe format
  $programWithPlatfomTVAExe = $programTVAExe.Replace(".exe", "_$selectedPlatform.exe")
  $programWithPlatfomTVSExe = $programTVSExe.Replace(".exe", "_$selectedPlatform.exe")
  $programWithPlatfomTVCExe = $programTVCExe.Replace(".exe", "_$selectedPlatform.exe")
  $programWithPlatfomTVMExe = $programTVMExe.Replace(".exe", "_$selectedPlatform.exe")
  $programWithPlatfomRExe = $programRInstallExe.Replace(".exe", "_$selectedPlatform.exe")
  $programWithPlatfomRFSExe = $programRFSExe.Replace(".exe", "_$selectedPlatform.exe")
  $yearRegex = "201[7,8]*"

  if ($testGallery) {
    $versionA = Get-ChildItem "$galleryDir\$programTV\$parentVersion$selectedFlavourFolderName$programTVA" | Where-Object { (($_.Name -like $yearRegex) -and !($_.Name -like "*_7")) } | Sort-Object -descending | Select-Object Name -first 1
    $versionA = $versionA.Name
    $versionS = Get-ChildItem "$galleryDir\$programTV\$parentVersion$selectedFlavourFolderName$programTVS" | Where-Object { (($_.Name -like $yearRegex) -and !($_.Name -like "*_7")) } | Sort-Object -descending | Select-Object Name -first 1
    $versionS = $versionS.Name
    $versionC = Get-ChildItem "$galleryDir\$programTV\$parentVersion$selectedFlavourFolderName$programTVC" | Where-Object { (($_.Name -like $yearRegex) -and !($_.Name -like "*_7")) } | Sort-Object -descending | Select-Object Name -first 1
    $versionC = $versionC.Name
    $versionM = Get-ChildItem "$galleryDir\$programTV\$parentVersion$selectedFlavourFolderName$programTVM" | Where-Object { (($_.Name -like $yearRegex) -and !($_.Name -like "*_7")) } | Sort-Object -descending | Select-Object Name -first 1
    $versionM = $versionM.Name
    $versionR = Get-ChildItem "$galleryDir\$programR\$parentVersion$selectedFlavourFolderName" | Where-Object { (($_.Name -like $yearRegex) -and !($_.Name -like "*_7")) } | Sort-Object -descending | Select-Object Name -first 1
    $versionR = $versionR.Name
	if ($selectedPlatform -eq "x86") {
      $versionRFS = Get-ChildItem "$galleryDir\$programRFS\$parentVersion$releaseFolderName" | Where-Object { (($_.Name -like $yearRegex) -and !($_.Name -like "*_7")) } | Sort-Object -descending | Select-Object Name -first 1
      $versionRFS = $versionRFS.Name
	} else {
	  $versionRFS = "x64 not supported"
	}
  } else {
    $programTVC = "$programTVC" + "7"
    $programTVM = "$programTVM" + "7"
    $versionA = Get-ChildItem "$galleryDir\$programTV\$parentVersion$selectedFlavourFolderName$programTVA" | Where-Object { (($_.Name -like $yearRegex) -and ($_.Name -like "*_7")) } | Sort-Object -descending | Select-Object Name -first 1
    $versionA = $versionA.Name
    $versionS = Get-ChildItem "$galleryDir\$programTV\$parentVersion$selectedFlavourFolderName$programTVS" | Where-Object { (($_.Name -like $yearRegex) -and ($_.Name -like "*_7")) } | Sort-Object -descending | Select-Object Name -first 1
    $versionS = $versionS.Name
    $versionC = Get-ChildItem "$galleryDir\$programTV\$parentVersion$selectedFlavourFolderName$programTVC" | Where-Object { $_.Name -like $yearRegex } | Sort-Object -descending | Select-Object Name -first 1
    $versionC = $versionC.Name
    $versionM = Get-ChildItem "$galleryDir\$programTV\$parentVersion$selectedFlavourFolderName$programTVM" | Where-Object { $_.Name -like $yearRegex } | Sort-Object -descending | Select-Object Name -first 1
    $versionM = $versionM.Name
  }
} else {
  $versionObject = New-Object PSObject -Property @{
    'Major' = $versionToInstall.split(".")[0]
    'Minor' = $versionToInstall.split(".")[1]
    'Revision' = $versionToInstall.split(".")[2]
  }

  # Create parent version folder
  $parentVersion = $versionObject.Major + "." + $versionObject.Minor + ".x" + "\"

  if (!($PSBoundParameters.ContainsKey('galleryRFS')) -and !($PSBoundParameters.ContainsKey('galleryRecorder'))) {
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
  }

  $programAFound = $false
  $programSFound = $false
  $programCFound = $false
  $programMFound = $false
  $programRFound = $false
  $programRFSFound = $false

  $programWithPlatfomTVAExe = $programTVAExe
  $programWithPlatfomTVSExe = $programTVSExe
  $programWithPlatfomTVCExe = $programTVCExe
  $programWithPlatfomTVMExe = $programTVMExe
  $programWithPlatfomRExe = $ProgramRInstallExe
  $programWithPlatfomRFSExe = $programRFSExe
  
  # Work up from 0 to n where n is the revision in the version - not all will be at that version
  for($i=0; $i -le ($versionObject.Revision); $i++) {
    $versionText = $versionObject.Major + "." + $versionObject.Minor + "." + $i
    if (Test-Path "$galleryDir\$programTV\$parentVersion$selectedFlavourFolderName$programTVA\$platform\$versionText") {
      $versionA = $versionText
	  # Check if the exe is platform agnostic or platform specific
      if (Test-Path "$galleryDir\$programTV\$parentVersion$selectedFlavourFolderName$programTVA\$versionText\$platform\$programWithPlatfomTVAExe") {
	    $programAFound = $true
	  } else {
	    $programWithPlatfomTVAExe = $programTVAExe.Replace(".exe", "_$selectedPlatform.exe")
        if (Test-Path "$galleryDir\$programTV\$parentVersion$selectedFlavourFolderName$programTVA\$versionText\$platform\$programWithPlatfomTVAExe") {
	      $programAFound = $true
	    }
      }
    }
    if (Test-Path "$galleryDir\$programTV\$parentVersion$selectedFlavourFolderName$programTVS\$platform\$versionText") {
      $versionS = $versionText
	  # Check if the exe is platform agnostic or platform specific
      if (Test-Path "$galleryDir\$programTV\$parentVersion$selectedFlavourFolderName$programTVS\$versionText\$platform\$programWithPlatfomTVSExe") {
	    $programSFound = $true
	  } else {
	    $programWithPlatfomTVSExe = $programTVSExe.Replace(".exe", "_$selectedPlatform.exe")
        if (Test-Path "$galleryDir\$programTV\$parentVersion$selectedFlavourFolderName$programTVS\$versionText\$platform\$programWithPlatfomTVSExe") {
	      $programSFound = $true
	    }
      }
    }
    if (Test-Path "$galleryDir\$programTV\$parentVersion$selectedFlavourFolderName$programTVC\$platform\$versionText") {
      $versionC = $versionText
	  # Check if the exe is platform agnostic or platform specific
      if (Test-Path "$galleryDir\$programTV\$parentVersion$selectedFlavourFolderName$programTVC\$versionText\$platform\$programWithPlatfomTVCExe") {
	    $programCFound = $true
	  } else {
	    $programWithPlatfomTVCExe = $programTVCExe.Replace(".exe", "_$selectedPlatform.exe")
        if (Test-Path "$galleryDir\$programTV\$parentVersion$selectedFlavourFolderName$programTVC\$versionText\$platform\$programWithPlatfomTVCExe") {
	      $programCFound = $true
	    }
      }
    }
    if (Test-Path "$galleryDir\$programTV\$parentVersion$selectedFlavourFolderName$programTVM\$platform\$versionText") {
      $versionM = $versionText
	  # Check if the exe is platform agnostic or platform specific
      if (Test-Path "$galleryDir\$programTV\$parentVersion$selectedFlavourFolderName$programTVM\$versionText\$platform\$programWithPlatfomTVMExe") {
	    $programMFound = $true
	  } else {
	    $programWithPlatfomTVMExe = $programTVMExe.Replace(".exe", "_$selectedPlatform.exe")
        if (Test-Path "$galleryDir\$programTV\$parentVersion$selectedFlavourFolderName$programTVM\$versionText\$platform\$programWithPlatfomTVMExe") {
	      $programMFound = $true
	    }
      }
    }
	
    if (Test-Path "$galleryDir\$programR\$parentVersion$selectedFlavourFolderName\$platform\$versionText") {
      $versionR = $versionText
	  # Check if the exe is platform agnostic or platform specific
      if (Test-Path "$galleryDir\$programR\$parentVersion$selectedFlavourFolderName\$programTVRFS\$versionText\$programWithPlatfomRExe") {
	    $programRFound = $true
	  } else {
	    $programWithPlatfomRExe = $ProgramRInstallExe.Replace(".exe", "_$selectedPlatform.exe")
        if (Test-Path "$galleryDir\$programR\$parentVersion$selectedFlavourFolderName\$programTVR\$versionText\$programWithPlatfomRExe") {
	      $programRFound = $true
	    }
      }
    }

    if (Test-Path "$galleryDir\$programRFS\$parentVersion\$platform\$versionText") {
      $versionRFS = $versionText
	  # Check if the exe is platform agnostic or platform specific
      if (Test-Path "$galleryDir\$programRFS\$parentVersion\$programTVRFS\$versionText\$programWithPlatfomRFSExe") {
	    $programRFSFound = $true
	  } else {
	    $programWithPlatfomRFSExe = $programRFSExe.Replace(".exe", "_$selectedPlatform.exe")
        if (Test-Path "$galleryDir\$programRFS\$parentVersion\$programTVRFS\$versionText\$programWithPlatfomRFSExe") {
	      $programRFSFound = $true
	    }
      }
    }
  }

  
  if (!($PSBoundParameters.ContainsKey('galleryRFS')) -and !($PSBoundParameters.ContainsKey('galleryRecorder'))) {
    if ((!$programAFound) -or (!$programSFound) -or (!$programCFound) -or (!$programMFound)) {
      if (!$programAFound) {
        Write-Host "$programTVAExe not found for $versionA";
      }
      if (!$programSFound) {
        Write-Host "$programTVSExe not found for $versionS"
      }
      if (!$programCFound) {
        Write-Host "$programTVCExe not found for $versionC"
      }
      if (!$programMFound) {
        Write-Host "$programTVMExe not found for $versionM"
      }
      return
    }
  }
}

# Only show RFS if we have param galleryRFS or testGallery x86
$showRFS = (($PSBoundParameters.ContainsKey('galleryRFS')) -or $testGallery)
$showRecorder = (($PSBoundParameters.ContainsKey('galleryRecorder')) -or $testGallery)
# Show Vision if galleryRFS or galleryRecorder not selected
$showVision = !(($PSBoundParameters.ContainsKey('galleryRFS')) -or ($PSBoundParameters.ContainsKey('galleryRFS')))

if (!($PSBoundParameters.ContainsKey('galleryRFS')) -and !($PSBoundParameters.ContainsKey('galleryRecorder'))) {
  Write-Host "Version detection is as follows: `n"
  Write-Host "$programTVA $versionA ($selectedPlatform)"
  Write-Host "$programTVS $versionS ($selectedPlatform)"
  Write-Host "$programTVC $versionC ($selectedPlatform)"
  Write-Host "$programTVM $versionM ($selectedPlatform)"
  if ($showRecorder) {
    Write-Host "$programR $versionR ($selectedPlatform)"
  }
}

if ($showRFS) {
  if ($selectedPlatform -eq "x86") {
    Write-Host "$programRFS $versionRFS ($selectedPlatform only)"
  } else {
    Write-Host "$programRFS $versionRFS"
  }
}

if ($showRecorder) {
  if ($selectedPlatform -eq "x86") {
    Write-Host "$programR $versionR ($selectedPlatform only)"
  } else {
    Write-Host "$programR $versionR"
  }
}

$confirmation = Read-Host "Do you want to install these versions? (y/n) Or a selection (s)"

# Clear all the read prompt response for this script - do it here in case we exit the script early
Clear-History -Command "Read-Host"

if ($confirmation -Match 'n') {
  return
} else {
  if ($confirmation -Match 's') {
    if ($showVision) {
	  Write-Host "`n1   Admin"
	  Write-Host "2   Server"
	  Write-Host "3   Client"
	  Write-Host "4   Multiplexer"
    }
	if ($showRecorder) {
	  Write-Host "5   Recorder"
	}
	if ($showRFS) {
	  Write-Host "6   RFS"
	}
    $selection = Read-Host "Enter a single number or CSV list of numbers for the programs you wish to install"

    # Clear all the read prompt response for this script - do it here in case we exit the script early
    Clear-History -Command "Read-Host"

	foreach($singleSelection in $selection.split(",")) {
	  if ($singleSelection.trim() -eq 1) { $installA = $true }
	  if ($singleSelection.trim() -eq 2) { $installS = $true }
	  if ($singleSelection.trim() -eq 3) { $installC = $true }
	  if ($singleSelection.trim() -eq 4) { $installM = $true }
	  if ($singleSelection.trim() -eq 5) { $installR = $true }
	  if ($singleSelection.trim() -eq 6) { $installRFS = $true }
	}
  } else {
    if ($galleryRFS) {
      $installA = $false
      $installS = $false
      $installC = $false
      $installM = $false
      $installR = $false
      $installRFS = $true
	}
	else {
      if ($galleryRecorder) {
        $installA = $false
        $installS = $false
        $installC = $false
        $installM = $false
        $installR = $true
        $installRFS = $false
	  } else {
        $installA = $true
        $installS = $true
        $installC = $true
        $installM = $true
        $installR = $false
        $installR = $false
      }
	}
  }
}

if ($installA -eq $true) {
  # Check if program is running
  $processA = Get-Process | Where-Object { $_.Name -eq "$processTVAName" }
  if ($processA.Name -ne "$processTVAName") {
    Write-Host "Installing $selectedFlavour $programTVA $versionA"
    & "$galleryDir\$programTV\$parentVersion$selectedFlavourFolderName$programTVA\$versionA\$programWithPlatfomTVAExe" /silent /suppressmsgboxes | Out-Null
    if ($LastExitCode -ne 0) { Write-Host "Error"; return}
  } else {
    "Install aborted - $processTVAName already running"
  }
}

if ($installS -eq $true) {
  StopAndRemoveRunningService($serviceProgramTVS)
  if (!(IsProcessRunning($processTVSName))) {
    Write-Host "Installing $selectedFlavour $programTVS $versionS"
    & "$galleryDir\$programTV\$parentVersion$selectedFlavourFolderName$programTVS\$versionS\$programWithPlatfomTVSExe" /silent /suppressmsgboxes | Out-Null
    if ($LastExitCode -ne 0) { Write-Host "Error"; return}
  } else {
    "Install aborted - $processTVSName already running"
  }
}

if ($installC -eq $true) {
  if (!(IsProcessRunning($processTVCName))) {
    Write-Host "Installing $selectedFlavour $programTVC $versionC"
    & "$galleryDir\$programTV\$parentVersion$selectedFlavourFolderName$programTVC\$versionC\$programWithPlatfomTVCExe" /silent /suppressmsgboxes | Out-Null
    if ($LastExitCode -ne 0) { Write-Host "Error"; return}
  } else {
    "Install aborted - $processTVCName already running"
  }
}

if ($installM -eq $true) {
  if (!(IsProcessRunning($processTVMName))) {
    Write-Host "Installing $selectedFlavour $programTVM $versionM"
    & "$galleryDir\$programTV\$parentVersion$selectedFlavourFolderName$programTVM\$versionM\$programWithPlatfomTVMExe" /silent /suppressmsgboxes | Out-Null
    if ($LastExitCode -ne 0) { Write-Host "Error"; return}
  } else {
    "Install aborted - $processTVMName already running"
  }
}

if (($testGallery) -or ($galleryRecorder)) {
  if ($installR -eq $true) {
    if (!(IsProcessRunning($processTVRName))) {
      Write-Host "Installing $selectedFlavour $programR $versionR"
      & "$galleryDir\$programR\$parentVersion$selectedFlavourFolderName\$versionR\$programWithPlatfomRExe" /silent /suppressmsgboxes | Out-Null
      if ($LastExitCode -ne 0) { Write-Host "Error"; return}
    } else {
      "Install aborted - $processTVRName already running"
    }
  }
}
if ($installRFS -eq $true) {
  $extraParentFolder = ""
  if ($testGallery) {
    $extraParentFolder = "Release"
  }
  Write-Host "Installing Release $programRFS $versionRFS"
  & "$galleryDir\$programRFS\$parentVersion\$extraParentFolder\$versionRFS\$programWithPlatfomRFSExe" /silent /suppressmsgboxes | Out-Null
  if ($LastExitCode -ne 0) { Write-Host "Error"; return}

  $startServiceResponse = Read-Host "Do you want to start the RFSService? (y/n)"
  if ($startServiceResponse -Match 'y') {
    Start-Service RFSService
  }
}