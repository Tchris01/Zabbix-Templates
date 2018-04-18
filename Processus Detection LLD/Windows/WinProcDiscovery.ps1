# Name getprocWin.ps1
# This will output specific details for mountpoints
$i = 0

$process = Get-process
#win32_volume -Filter "DriveLetter IS NULL AND DriveType = '3'" | where {$_.Name -notlike "\\?\*"}


write-host "{"
write-host " `"data`":["
write-host 


if ($process -eq $null) {write-host "]}" }

foreach ( $proc in $process )
 {
 if (($i -eq $process.Count - 1) -or ( $process.Count -eq $null )) 
  {
   $line =  " { `"{#PROCNAME}`":`"" + $proc.ProcessName + "`" }]}"
  }
 else
  {
   $line =  " { `"{#PROCNAME}`":`"" + $proc.ProcessName + "`" },"
  }
 write-host $line
 $i = $i + 1
 }
