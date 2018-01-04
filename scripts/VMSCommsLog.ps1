$events = Get-WinEvent @{logname='application'} -maxevents 1000 | Where-Object { $_.ProviderName -eq "VMSComms" } | Select -first 40

$output = ""
for($i=0; $i -lt $events.length ; $i++) {
  $logMessage = $events[$i].Message
  $output = $output + $events[$i].TimeCreated.ToString("HH:mm:ss") + "    " + $logMessage + "`r`n"
  if ($events[$i].Message.Contains("VMSComms service started")) {
	break;
  }
}

return $output
