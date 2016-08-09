# Starting up Slack doesn't display the icon properly (just displays standard Windows program icon)
# pinning and unpinning the icon will cause the correct icon to be displayed

$shell = new-object -com "Shell.Application"  
$folder = $shell.Namespace('C:\Users\tmackenzie01\AppData\Local\slack') 
$item = $folder.Parsename('Update.exe')
$verb = $item.Verbs() | ? {$_.Name -eq 'Pin to Tas&kbar'}
if ($verb) {$verb.DoIt()}
$verb = $item.Verbs() | ? {$_.Name -eq 'Unpin from Tas&kbar'}
if ($verb) {$verb.DoIt()}