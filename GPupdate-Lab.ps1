$Lab = "TMT124"
$img = "A"
$start = 1
$end = 24
$cns = $start..$end | ForEach-Object {$_.tostring("000")} | % {"L$($Lab)$($img)$($_)"}

$creds = Get-Credential

foreach($cn in $cns)
    {
        Try
            {
                #Invoke-Command -ComputerName $cn -Credential $creds -FilePath "\\cold.grcc.edu\sccm\Settings\Shortcuts\EquationEditor\Create-Shortcut.ps1"
                $job = Invoke-Command -ComputerName $cn -Credential $creds -AsJob -JobName $cn -ScriptBlock {& gpupdate /force}
                #Invoke-Command -ComputerName $cn -Credential $($creds) -AsJob -JobName $cn -FilePath \\cold\sccm\apps\Sage50\2017\Fix-Launch.ps1
            }
        Catch{Write-Host $error[0].Exception.Message}
    }

foreach($cn in $cns)
    {
    Write-Host "`r`n`r`n"
    IF(Test-Connection -ComputerName $cn -Count 1 -ea SilentlyContinue)
        {            
        $joboutput = Get-Job $cn | Wait-Job | Receive-Job
        Write-Host "$CN`:"
        $joboutput | Where {$_}
        }
    Else
        {
        Write-Host "$CN`: `nNot Reachable"
        }
    }