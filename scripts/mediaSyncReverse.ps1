$visionServerDir = "C:\Program Files (x86)\Titan\Vision Server"
$visionServerDefaultSitesDir = "$visionServerDir\sites\default"
$visionServerDefaultSitesDirExists = Test-Path $visionServerDefaultSitesDir
$visionClientDir = "C:\CodeSandbox\TitanVision_trunk\source\clientbin"
$visionClientSitesDir = "$visionClientDir\sites"
$visionClientSitesDirExists = Test-Path $visionClientSitesDir

$backupServerSites = "C:\ProgramData\Titan\Backups\MediaBackupServer"
$backupClientSites = "C:\ProgramData\Titan\Backups\MediaBackupClient"

$newMediaFolder = "C:\ProgramData\Titan\Media"

if (![system.io.directory]::Exists($visionServerDefaultSitesDir)) {
  Write-Host "Moving $backupServerSites to $visionServerDefaultSitesDir"
  Move-Item $backupServerSites $visionServerDefaultSitesDir
}

if (![system.io.directory]::Exists($visionClientSitesDir)) {
  Write-Host "Moving $backupClientSites to $visionClientSitesDir"
  Move-Item $backupClientSites $visionClientSitesDir
}

if ([system.io.directory]::Exists($newMediaFolder)) {
  [system.io.directory]::Delete($newMediaFolder, "true")

  if (![system.io.directory]::Exists($newMediaFolder)) {
    Write-Host "$newMediaFolder deleted"
  }
}

Write-Host "Creating VISION share at $visionServerDefaultSitesDir"
cmd /c $( "net share VISION=""$visionServerDefaultSitesDir""" )
Write-Host "net share VISION='$visionServerDefaultSitesDir'"
