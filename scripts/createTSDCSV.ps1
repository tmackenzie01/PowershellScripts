$dayCounts = Import-Csv "D:\Users\thomas\My DropBox\My Dropbox\TurboInhaler\Raw day counts.txt"

$output = "";
$currentDate = Get-Date -date "2017-07-01 00:00:00"
for ($i = 0; $i -lt $dayCounts.Length; $i++) {
  # Get counts for the day
  $singleDay = $dayCounts[$i].Value;
  
  # Set does date to current day 7 am
  $currentDayDate = $currentDate.ToString("yyyy-MM-dd");
  $doseDate = Get-Date -date "$currentDayDate 07:00:00"
  
  for ($j = 0; $j -lt $singleDay; $j++) {
    # Separate each dose by an hour
    $output = $output + $doseDate.ToString("1,yyyy-MM-dd HH:mm:ss");
	$output = $output + "/";
    $doseDate = $doseDate.AddHours(1);
  }
  $currentDate = $currentDate.AddDays(1);
}

return $output;