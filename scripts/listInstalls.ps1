$uninstallRoots = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall", "HKLM\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
  
  ForEach ($uninstallRoot in $uninstallRoots) {
    $uninstalls = Get-ChildItem -path Registry::$uninstallRoot | Select-Object Name
  
    ForEach ($u in $uninstalls) {
	  $fullReg = $u
	  $fullReg = $fullReg -replace "@{Name=HKEY_LOCAL_MACHINE","HKLM:"
	  $fullReg = $fullReg -replace "}}","}"
	  Write-Output $fullReg
	  Try {
	    if (Test-Path $fullReg) {	  
          $displayName = Get-ItemProperty -Path $fullReg -name DisplayName | Select-Object DisplayName
          Write-Output $displayName.DisplayName
        }
      }
      Catch {
      }
    }
    Write-Output "*********************"
  }