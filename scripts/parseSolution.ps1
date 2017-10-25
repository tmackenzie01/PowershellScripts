Param($solutionFile)

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
foreach ($configuration in $configurations) {
  foreach ($platform in $platforms) {
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
      #$output = $output + "##`n"
      #$output = $output + "FOUND: $projectGuidName`n"
      #$output = $output + "FOUND: $projectName`n"
      #$output = $output + "##`n"
	
      #$output = $output + "$guid ($projectName)`n"
      $displayLine = $displayLine.Replace($guid, $projectName)
      $output = $output + "$displayLine`n"
    }
    $output = $output + "`n"
  }  
}

return $output