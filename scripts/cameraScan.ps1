try
{
  $webClient = New-Object System.Net.WebClient
  #$webClient.DownloadString("http://www.google.com")
  $webClient.DownloadString("http://172.16.2.101/guest/main.html")
}
catch [Net.WebException] {
  Write-Host $_.Exception.ToString()
  Write-Host "*** $_.Exception.Message.ToString() ***"
}