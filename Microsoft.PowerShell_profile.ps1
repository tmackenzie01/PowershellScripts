Write-Host "Loading profile for PowerShell" $PSVersionTable.PSVersion.Major $PSVersionTable.PSVersion.Minor

# Aliases
Set-Alias npp ${env:ProgramFiles(x86)}\Notepad++\notepad++.exe

# Reload profile
function Reload-Profile() {
  # This is just . $profile, but at the moment I won't remember that
  . $profile
  Write-Host "May not pick up changes for existing functions, try re-launching PowerShell"
}

# SQL Server functionality
function Tsql ($query) {
  sqlcmd -S 127.0.0.1\SQLEXPRESS -d VMS_DevConfig -Q $query
}

function Tsql-Open-Backups() {
  explorer "C:\Users\tmackenzie01\Documents\Customer DBs"
}

function Tsql-Restore-Backup ($backup) {
  sqlcmd -S 127.0.0.1\SQLEXPRESS -Q "RESTORE DATABASE VMS_DevConfig FROM DISK = '$backup'"
}

function Tsql-Delete-Database() {
  $confirmation = Read-Host "This will delete VMS_DevConfig, do you want to continue? (y/n)"
  If ($confirmation -Match 'y') {
    Write-Host "Database VMS_DevConfig deletion in progress ..."
    sqlcmd -S 127.0.0.1\SQLEXPRESS -Q "DROP DATABASE VMS_DevConfig"
    Write-Host "Database VMS_DevConfig deleted"
  }
  else {
    Write-Host "No database VMS_DevConfig deletion performed"
  }
}

function Tsql-List-Databases() {
  # "SET NOCOUNT ON" means the "(N rows affected)" at the bottom of the query is not displayed
  $nocount = "SET NOCOUNT ON"
  # -W removes trailing spaces, -h -1 specifies no headers to be shown, https://msdn.microsoft.com/en-us/library/ms162773.aspx 
  $query = "SELECT name FROM master..sysdatabases WHERE name <> 'tempdb' AND name <> 'model' AND name <> 'msdb'"
  $queryResults = sqlcmd -S 127.0.0.1\SQLEXPRESS -Q "$nocount;$query" -W -h -1
  if ($queryResults -contains "VMS_DevConfig") {
    # Get the version number
    $versionNumber = sqlcmd -S 127.0.0.1\SQLEXPRESS -d VMS_DevConfig -Q "SET NOCOUNT ON;SELECT major_number, minor_number, revision FROM tblVersionNumber WHERE is_current=1;SET NOCOUNT OFF" -W -h -1
	$versionNumber = $versionNumber -replace " ","."
	
	#Get the build type (case statement converts it from number to text)
	$buildType = sqlcmd -S 127.0.0.1\SQLEXPRESS -d VMS_DevConfig -Q "SET NOCOUNT ON;SELECT CASE WHEN build_type = 3 THEN 'GeoLog Secure' WHEN build_type = 1 THEN 'Titan Secure' WHEN build_type = 2 THEN 'Titan Standard' WHEN build_type = 4 THEN 'Insecure' ELSE 'Unknown' END FROM tblVersionNumber WHERE is_current=1" -W -h -1	
	
	$queryResults = "VMS_DevConfig" + " " + $versionNumber + " " + $buildType
  }
  
  Write-Host $queryResults
}

function sign ($filename) {
  $cert = @(gci cert:\currentuser\My -codesign)[0]
  Set-AuthenticodeSignature $filename $cert
}

# SIG # Begin signature block
# MIIFuQYJKoZIhvcNAQcCoIIFqjCCBaYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUKxvZg1iwRrz4TMrbVTG7Trtf
# hVygggNCMIIDPjCCAiqgAwIBAgIQuoXR2byjco1JfjGaYnjWJjAJBgUrDgMCHQUA
# MCwxKjAoBgNVBAMTIVBvd2VyU2hlbGwgTG9jYWwgQ2VydGlmaWNhdGUgUm9vdDAe
# Fw0xNTA1MDYwODM5MDBaFw0zOTEyMzEyMzU5NTlaMBoxGDAWBgNVBAMTD1Bvd2Vy
# U2hlbGwgVXNlcjCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBALRYSXjI
# gSEXUTezL1O/mObDjWv1XoftMlSvN1kifO64psG/41twoCdkyaZImQoaDPnbRr+i
# uLISpcSfJ7skbvTnRx8F3Ms98Pi/4pmwU6C6hLt8GKA556Frd2+puf+0gtAvetXT
# EnhLZoJFJOV0dFxa8kYeNvhx59rTI3Dniojd8bUXFz9TQVKhtOsCg7byewmHuu9T
# khzBshIy1ezNvYW3kS+yBNLiDcqxGqXeW4qXCC4CoDlVV1rMfVcqgHhg8hRG6K3Q
# afCCE5seh2IRVThIYzRXAQ8p951EtMAyaK06/NUE2dmYIM+iam1RY64nVFV8/LEe
# tIq/ZBSGpwOfDaUCAwEAAaN2MHQwEwYDVR0lBAwwCgYIKwYBBQUHAwMwXQYDVR0B
# BFYwVIAQuS5doYTbp8lzZU+lF2zZ/aEuMCwxKjAoBgNVBAMTIVBvd2VyU2hlbGwg
# TG9jYWwgQ2VydGlmaWNhdGUgUm9vdIIQqyhqM7qTL7pIBrc5nvIk3DAJBgUrDgMC
# HQUAA4IBAQBxerO14kZ8frAawSxqcTJ9jYNg+L7rIs923pvyuFpQ5+WM7bzxkiNV
# 9PJoXRGTuUAljMPPol9e4t/JWbKmf6jUKgSpWH7IUkeSbpZ5cpDzIofUfNZtUDsZ
# 23l+kAQByRgoXYN/I9M/woIO8BcCWr6mLTcap3SXZ2GU29K+sjXbRlybwTRLbvxp
# 9Y22uz8BdGH1R3v3gW3JSOQe1K4zNyBzRzTGWF/P6/jlHkbOVp7qruS/cIAfMt4+
# ps8/SQVWPrMxyXRcs7+yNNCWD5+Q7/AhwEFx7A/irDaENssd/iC6UXpMV4/tYFDl
# DdkWLErnGUpWlOHwraiLWF6G+3pa36aAMYIB4TCCAd0CAQEwQDAsMSowKAYDVQQD
# EyFQb3dlclNoZWxsIExvY2FsIENlcnRpZmljYXRlIFJvb3QCELqF0dm8o3KNSX4x
# mmJ41iYwCQYFKw4DAhoFAKB4MBgGCisGAQQBgjcCAQwxCjAIoAKAAKECgAAwGQYJ
# KoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEOMAwGCisGAQQB
# gjcCARUwIwYJKoZIhvcNAQkEMRYEFCHi/UjFo9EqI4FR3z9wErVPjStSMA0GCSqG
# SIb3DQEBAQUABIIBAKe4jAt+crqJxqRg8jCH+UDtCIjXEicSm9Lc+m7d0HwmUISx
# x53AlzhWzaNwpPpFt8RvWIrls3EEub0m2/Or9k2f4DYYD6qGXBDo9GathVjnJmf1
# +DFMqzDWwEOVBu2rU8LhTTwiqzibJ/rIO+CTmK3+oqmr6hkNw7u9596FD/OZBDFe
# 8+fy+QjWBjZqkuNxgrTXCwst5JJg4GLjGiQxPipaQZr9Y57eVp0HY1SxTx6FKJxN
# BcpDfF8jhBEylM2Sxw1PGu1y8urMb+TgmOGgflThpdOH2nr2CUTqnBkmMKmb7AKx
# xiUTy3BfEBiXTwfPVxjDXdxwgQbWbPjRsafRX2s=
# SIG # End signature block
