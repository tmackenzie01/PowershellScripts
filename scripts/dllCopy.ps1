# http://www.hanselman.com/blog/SigningPowerShellScripts.aspx
# Set-AuthenticodeSignature .\test.ps1 @(Get-ChildItem cert:\CurrentUser\My -codesign)[0]
$codeRootFolder = "C:\CodeSandbox"
$sourceDlls = "$codeRootFolder\VMSColdstore_clean\source\VMSColdstore\bin\Debug\VMSColdstore.dll",
			"$codeRootFolder\VMSColdstore_clean\source\VMSColdstore\bin\Debug\VMSColdstoreNetApi.dll",
			"$codeRootFolder\VMSColdstore_clean\source\VMSColdstore\bin\Debug\VMSTrinity.dll",
			"$codeRootFolder\VMSComms_trunk\source\VMSCommsTCP\bin\Debug\VMSCommsTCP.dll",
			"$codeRootFolder\VMSComms_trunk\source\VMSCommsSSL\bin\Debug\VMSCommsSSL.dll"
			
$repos = "TitanRecorder_trunk", "TitanRecorder_clean", "TitanVision_clean"

# Check arguments for -Revert or -revert
$revert = $false
ForEach ($arg in $args)
{
  if (($arg -eq '-Revert') -and ($arg -eq '-revert')) {
    $revert = $true
  }
}

if (!$revert) {
  Write-Host "About to copy"$sourceDlls.length"items"
  ForEach ($sourceDll in $sourceDlls) {
	Write-Host "Copying $sourceDll ..."
	ForEach ($repo in $repos) {
		  $dllFolder = "$codeRootFolder\${repo}\Dependencies_svn\dlls\internal"
		  Write-Host "   to $repo ..."
		  Copy-Item $sourceDll $dllFolder
		  $sourcePdb = $sourceDll -replace ".dll",".pdb"
		  Copy-Item $sourcePdb $dllFolder
	  }
	  Copy-Item $sourceDll "$codeRootFolder"
  }
}
else {
  Write-Host "Reverting files"
  ForEach ($sourceDll in $sourceDlls) {
	ForEach ($repo in $repos) {
	  $filenameOnly = [system.io.path]::GetFilename($sourceDll)
	  $filenameDllOnly = $filenameOnly -replace ".dll",".pdb"
	  $fullPathDll = "$codeRootFolder\${repo}\Dependencies_svn\dlls\internal\$filenameOnly"
	  $fullPathPdb = "$codeRootFolder\${repo}\Dependencies_svn\dlls\internal\$filenameDllOnly"
	  Write-Host "Reverting ... $fullPathDll"
	  svn revert $fullPathDll
	  Write-Host "Reverting ... $fullPathPdb"
	  svn revert $fullPathPdb
	}
  }
}
