$Lab = "ATC228"
$img = "A"
$start = 1
$end = 25
$cns = $start..$end | ForEach-Object {$_.tostring("000")} | % {"L$($Lab)$($img)$($_)"}

$creds = Get-Credential

foreach($cn in $cns)
    {
        Try
            {
                #Invoke-Command -ComputerName $cn -Credential $creds -FilePath "\\cold.grcc.edu\sccm\Settings\Shortcuts\EquationEditor\Create-Shortcut.ps1"
                $job = stop-Computer -ComputerName $CN -ErrorAction Stop -Verbose -AsJob -Force
                #Invoke-Command -ComputerName $cn -Credential $($creds) -AsJob -JobName $cn -FilePath \\cold\sccm\apps\Sage50\2017\Fix-Launch.ps1
                Write-host "$CN`: $($job.status)"
            }
        Catch{Write-Host $error[0].Exception.Message}
    }