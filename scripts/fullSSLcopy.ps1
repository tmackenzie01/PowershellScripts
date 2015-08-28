# http://www.hanselman.com/blog/SigningPowerShellScripts.aspx
# Set-AuthenticodeSignature .\test.ps1 @(Get-ChildItem cert:\CurrentUser\My -codesign)[0]
$source = "C:\CodeSandbox\FullSSL\TitanVision_fullSSL\VisionCommon\bin\Debug\VisionCommon.dll",
"C:\CodeSandbox\FullSSL\TitanVision_fullSSL\remotinglayer\commstypes\bin\Debug\CommsTypes.dll"

$destinations = "C:\CodeSandbox\FullSSL\AdminTool_fullSSL\Dependencies_svn\dlls\internal"
"C:\CodeSandbox\FullSSL\TitanRecorder_fullSSL\Dependencies_svn\dlls\internal",
"C:\CodeSandbox\FullSSL\TitanVision_fullSSL\Dependencies_svn\dlls\internal"

ForEach ($source in $source)
{
	Write-Host "Copying $source ..."
	ForEach ($dest in $destinations)
	{
		Copy-Item $source $dest
	}
	Write-Host "... complete"
}

# SIG # Begin signature block
# MIIFuQYJKoZIhvcNAQcCoIIFqjCCBaYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUtx0KmkqI0EP5ZR8UyxhClK9a
# FzugggNCMIIDPjCCAiqgAwIBAgIQuoXR2byjco1JfjGaYnjWJjAJBgUrDgMCHQUA
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
# gjcCARUwIwYJKoZIhvcNAQkEMRYEFLqa3rxA7N46QEALuPd7ZW22Yr9wMA0GCSqG
# SIb3DQEBAQUABIIBAFi65UgChMnq/Hs868jrEwyeUcnxgF2kELTkcp5Ubq3Bnve8
# jxX/Bik2GUqnG7OVNMmm7sV2VfKv0bkdRr2Fdx3U79SLdJs81JucJ0/OuLDp17Tw
# 8/PrHBZ5wtKRKe5Ps09E7SqjhljLF6tr8Pm6/6FL08r3coXuNd9QGQCRUSf5ksG0
# y4sC/U1Js6jkXWp6h+DZ6wLUI3W99YYNTMs8TnEzCMd4M9iRquExq9s4TZsONfDe
# amS6aKQrPFZF+p56D4wXAMSm1deQh7TF6JJq52ZPHX32YyUguujLD86J98uUttEN
# Mo4humlG1D824Amj6Dis0VJI7tYo6QkgsV/oFRk=
# SIG # End signature block
