$Lab = "CAH100"
$img = "-"
$start = 1
$end = 30
$cns = $start..$end | ForEach-Object {$_.tostring("000")} | % {"L$($Lab)$($img)$($_)"}

$creds = Get-Credential

foreach($cn in $cns)
    {
        Try
            {
                #Invoke-Command -ComputerName $cn -Credential $creds -FilePath "\\cold.grcc.edu\sccm\Settings\Shortcuts\EquationEditor\Create-Shortcut.ps1"
                $job = Restart-Computer -ComputerName $CN -Force -ErrorAction Stop -Verbose -AsJob
                #Invoke-Command -ComputerName $cn -Credential $($creds) -AsJob -JobName $cn -FilePath \\cold\sccm\apps\Sage50\2017\Fix-Launch.ps1
                Write-host "$CN`: $($job.status)"
            }
        Catch{Write-Host $error[0].Exception.Message}
    }