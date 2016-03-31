[System.Reflection.Assembly]::LoadWithPartialName("System.Web.Extensions") > $null

# Check powershell include directory exists

if (!([System.IO.Directory]::Exists("$powershellIncludeDirectory"))) {
  Write-Host "Directory $powershellIncludeDirectory does not exist - can't build dependency file paths"
}

function CopyDlls([String] $rootFolder, [String] $source, [String] $dest) {
  $sourceSplit = $source.Split("_");
  $destSplit = $dest.Split("_");
  
  $project = $sourceSplit[0]
  $dest = "$rootFolder\$dest\Dependencies\dlls\internal"
  $json = Get-Content "$powershellIncludeDirectory\CodeComponents.json"
  $ser = New-Object System.Web.Script.Serialization.JavaScriptSerializer
  $obj = $ser.DeserializeObject($json)

  foreach ($dll in $obj.$project) {
    if ($dll.dll) {
      $dllFile = $dll.dll
      $dllPath = $dll.path
	  $dllPath = "$rootFolder\$project\source\$dllPath"
      Write-Host "Copy $dllFile from $dllPath\$dllFile to $dest"
    }
    else {
      Write-Host "Project dlls for $project not recognised"
    }
  }
}

CopyDlls -rootFolder "C:\Development\Code" -source 'V1_trunk' -dest "A_trunk"



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