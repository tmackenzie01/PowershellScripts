Param($solutionFile, [switch]$outputToFile)

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

if (!($PSBoundParameters.ContainsKey('solutionFile'))) {
  $solutionFile = "D:\CodeSandbox\Vision_trunk\source\Vision.sln"
}

$output = ""
$configurations = $($localInfo.VSBuildFlavours)
$platforms = "x86", "x64"
$buildConfigCount = 1
foreach ($configuration in $configurations) {
  foreach ($platform in $platforms) {
	$buildConfigOutput = ""
    $solutionFileContents = Get-ChildItem $solutionFile
    $lines = $solutionFileContents | Select-String "\.$configuration\|$platform" | Select-Object -Prop Line
    foreach ($line in $lines) {
      $displayLine = $line.Line.Trim()
      $displayLine = $displayLine.Replace(".ActiveCfg","")
      $displayLine = $displayLine.Replace(".Build.0","")

      # Get the GUID
      $split = $displayLine.split(".")
      $guid = $split[0]

      $guidSearch = ", ""$guid"""

      # Find the project name for the guid
      $projectLine = $solutionFileContents | Select-String "$guidSearch" | Select-Object -Prop Line | select -first 1
      $projectLineSplit = $projectLine.Line.split(",")
      $projectGuidName = $projectLineSplit[0]
      #$projectGuidName = $projectGuidName.Replace("""", "")
      $projectGuidNameSplit = $projectGuidName.split("=")
      $projectName = $projectGuidNameSplit[1].trim()
      $projectName = $projectName.replace("""", "")
      #$buildConfigOutput = $buildConfigOutput + "##`n"
      #$buildConfigOutput = $buildConfigOutput + "FOUND: $projectGuidName`n"
      #$buildConfigOutput = $buildConfigOutput + "FOUND: $projectName`n"
      #$buildConfigOutput = $buildConfigOutput + "##`n"
	
      #$buildConfigOutput = $buildConfigOutput + "$guid ($projectName)`n"
      $displayLine = $displayLine.Replace($guid, $projectName)
      #$buildConfigOutput = $buildConfigOutput + "$displayLine`n"
	  
	  $finalLineSplit = $displayLine.split("=")
	  $projectReleaseConfig = $finalLineSplit[0].PadRight(70)
	  $solutionReleaseConfig = $finalLineSplit[1]
      $buildConfigOutput = $buildConfigOutput + "$projectReleaseConfig = $solutionReleaseConfig`n"
    }

	$output = $output + $buildConfigOutput

    if ($PSBoundParameters.ContainsKey('outputToFile')) {
	  $buildConfigFilename = "D:\$buildConfigCount.txt"
	  $output = $output + "Writing to file $buildConfigFilename`n"
	  Set-Content $buildConfigFilename $buildConfigOutput
	}

	$buildConfigCount = $buildConfigCount + 1
    $output = $output + "`n"
  }  
}

return $output