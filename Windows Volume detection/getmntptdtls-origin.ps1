# Name getmntptdtls.ps1
# This will output specific details for mountpoints
$i = 0

$volumes = Get-WmiObject win32_volume -Filter "DriveLetter IS NULL AND DriveType = '3'" | where {$_.Name -notlike "\\?\*"}


write-host "{"
write-host " `"data`":["
write-host 


if ($volumes -eq $null) {write-host "]}" }

foreach ( $vol in $volumes )
 {
$vol.Name = $vol.name -replace '\\','\\'
 if (($i -eq $volumes.Count - 1) -or ( $volumes.Count -eq $null )) 
  {
   $line =  " { `"{#NAME}`":`"" + $vol.Name + "`" }]}"
  }
 else
  {
   $line =  " { `"{#NAME}`":`"" + $vol.Name + "`" },"
  }
 write-host $line
 $i = $i + 1
 }
