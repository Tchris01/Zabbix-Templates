# Name WinMntDiscovery-lg.ps1
# This will output specific details for mountpoints
# And detect OS Language for specific counter performance
$i = 0

$volumes = Get-WmiObject win32_volume -Filter "DriveType = '3'" | where {$_.Name -notlike "\\?\*"}
$language = Get-Culture

write-host "{"
write-host " `"data`":["
#write-host 


if ($volumes -eq $null) {write-host "]}" }

foreach ( $vol in $volumes )
 {
$vol.Name = $vol.name -replace '\\','\\'
$vol.Name = $vol.name -replace ':\\',':'
$vol.Name = $vol.name -replace ':\\',':'
 if (($i -eq $volumes.Count - 1) -or ( $volumes.Count -eq $null )) 
  {
   $line =  "{`"{#LANG}`":`"" + $language.Name + "`", {#NAME}`":`"" + $vol.Name + "`"}]}"
  }
 else
  {
   $line =  "{`"{#LANG}`":`"" + $language.Name + "`", {#NAME}`":`"" + $vol.Name + "`"},"
  }
 write-host $line
 $i = $i + 1
 }
