<#
.SYNOPSIS
Copies debug output dlls from built projects to the dependencies of other solutions

.DESCRIPTION
Requires local JSON files
CodeComponents.json (describes structure of solutions, their projects and output paths to dlls)
depsCopy_args.json (describes which projects to copy dlls from and to)

.EXAMPLE
./depsCopy_args.ps1

.EXAMPLE
./depsCopy_args.ps1 -revert

.LINK
http://github.com/tmackenzie01/PowershellScripts
#>

Param([switch] $revert)

[System.Reflection.Assembly]::LoadWithPartialName("System.Web.Extensions") > $null

# Check powershell include directory exists

if (!([System.IO.Directory]::Exists("$powershellIncludeDirectory"))) {
  Write-Host "Directory $powershellIncludeDirectory does not exist - can't build dependency file paths"
}

function CopyDlls([String] $rootFolder, [String] $source, [String] $dest) {
  $sourceSplit = $source.Split("_");
  $destSplit = $dest.Split("_");
  $fullSource = "$rootFolder\$source"
  
  $project = $sourceSplit[0]
  Write-Host "Copy $project dlls (and pdbs) to $dest ..."
  $dest = "$rootFolder\$dest\Dependencies_svn\dlls\internal"
  Write-Host "     ($dest)"
  $json = Get-Content "$powershellIncludeDirectory\CodeComponents.json"
  $ser = New-Object System.Web.Script.Serialization.JavaScriptSerializer
  $obj = $ser.DeserializeObject($json)
  
  # Confirm source repo directory exists
  if (!([System.IO.Directory]::Exists("$fullSource"))) {
    Write-Host "Directory $fullSource does not exist - can't copy file"
	exit
  }
  
  $fileCopyCount = 0
  $output = ""
  $errorOutput = ""
  $releaseDllsNewer = $false

  foreach ($dll in $obj.$project) {
    if ($dll.dll) {
      $dllFile = $dll.dll
      $dllPath = $dll.path
	  $dllPath = "$fullSource\source\$dllPath"
	  $sourceDll = "$dllPath\$dllFile"
	  $releaseSourceDll = $sourceDll -replace "\\Debug\\", "\Release\"

	  # Get times of source and release dlls
	  $sourceDllLastWrite = (Get-ChildItem $sourceDll).LastWriteTime
	  $releaseSourceDllLastWrite = (Get-ChildItem $releaseSourceDll).LastWriteTime

	  $dllFolder = $dest
	  $copyText = "$sourceDll -> $dllFolder"
	  if ($sourceDllLastWrite -le $releaseSourceDllLastWrite) {
        $errorOutput = $errorOutput + "$sourceDll`n"
        $releaseDllsNewer = $true
      } else {
        $output = $output + "$sourceDll`n"

        Copy-Item $sourceDll $dllFolder -errorAction Stop
        $fileCopyCount = $fileCopyCount + 1
        $sourcePdb = $sourceDll -replace ".dll",".pdb"
        Copy-Item $sourcePdb $dllFolder
        $fileCopyCount = $fileCopyCount + 1
      }
    }
    else {
      Write-Host "Project dlls for $project not recognised"
	  exit
    }
  }
  
  Write-Host $output -foregroundcolor yellow

  if ($releaseDllsNewer) {
    Write-Host "Some dlls have been built more recently as release, copy has not been performed" -foregroundcolor red
	Write-Host $errorOutput -foregroundcolor red
  }

  if ($fileCopyCount -eq 0) {
    Write-Host "No files copied" -foregroundcolor red
	exit
  }
}


function RevertDlls([String] $rootFolder, [String] $source, [String] $dest) {
  $sourceSplit = $source.Split("_");
  $destSplit = $dest.Split("_");
  $fullSource = "$rootFolder\$source"
  
  $project = $sourceSplit[0]
  $destNoRootFolder = "$dest\Dependencies_svn\dlls\internal"
  $dest = "$rootFolder\$dest\Dependencies_svn\dlls\internal"
  Write-Host "Revert changes in $destNoRootFolder ..."
  $json = Get-Content "$powershellIncludeDirectory\CodeComponents.json"
  $ser = New-Object System.Web.Script.Serialization.JavaScriptSerializer
  $obj = $ser.DeserializeObject($json)
  
  # Confirm source repo directory exists
  if (!([System.IO.Directory]::Exists("$fullSource"))) {
    Write-Host "Directory $fullSource does not exist - can't copy file"
	exit
  }
  
  $fileCopyCount = 0

  foreach ($dll in $obj.$project) {
    if ($dll.dll) {
      $dllFile = $dll.dll
      $dllPath = $dll.path
	  $dllPath = "$fullSource\source\$dllPath"
	  	  
	  $sourceDll = "$dllPath\$dllFile"
	  $dllFolder = $dest
	  $revertFile = "$dllFolder\$dllFile"
	  
	  Write-Host $revertFile
	  svn revert $revertFile
      $revertFile = $revertFile -replace ".dll",".pdb"
	  # This messes up the \dlls\ part of the path so just do this again - fix it properly later
      $revertFile = $revertFile -replace ".pdbs","\dlls"
	  Write-Host $revertFile
	  svn revert $revertFile
    }
    else {
      Write-Host "Project dlls for $project not recognised"
	  exit
    }
  }
}

# $sourceRepos & $destRepos read from depsCopy_args.json in C:\ProgramData\WindowsPowerShell includes
$sourceRepos = "TitanVision_trunk", "AdminTool_trunk"
$destRepos = ""
$sandboxPath = ""

if (([System.IO.Directory]::Exists("$powershellIncludeDirectory"))) {
  # Load args
  if (([System.IO.File]::Exists("$powershellIncludeDirectory\depsCopy_args.json"))) {
    $jsonFile = Get-Content "$powershellIncludeDirectory\depsCopy_args.json"
    $jsonSerializer = New-Object System.Web.Script.Serialization.JavaScriptSerializer
    $jsonArgs = $jsonSerializer.DeserializeObject($jsonFile)
	$sourceRepos = $jsonArgs.sourceRepos
	$destRepos = $jsonArgs.destRepos
	$sandboxPath = $jsonArgs.sandboxPath
  }
  else {
    Write-Host "Args file doesn't exist $powershellIncludeDirectory\depsCopy_args.json"
	exit
  }
}

if ($revert) {
  foreach ($sourceRepo in $sourceRepos) {
    foreach ($destRepo in $destRepos) {
      RevertDlls -rootFolder "$sandboxPath" -source "$sourceRepo" -dest "$destRepo"
    }
  }  
}
else {
  foreach ($sourceRepo in $sourceRepos) {
    foreach ($destRepo in $destRepos) {
      CopyDlls -rootFolder "$sandboxPath" -source "$sourceRepo" -dest "$destRepo"
    }
  }
}


#######################################################
# Example format of CodeComponents.json is as follows #
#######################################################
#{
#  "V1": [
#    {"dll": "V1A.dll","path": "V1A\\bin\\Debug", "pdb" : true},
#    {"dll": "V1B.dll", "path": "V1B\\bin\\Debug", "pdb" : true}
#  ],
#  "V2": [
#    {"dll": "V2A.dll","path": "V2A\\bin\\Debug", "pdb" : true},
#    {"dll": "V2B.dll", "path": "V2B\\bin\\Debug", "pdb" : true}
#  ]
#}