$source = "\\cold.grcc.edu\sccm\scripts\ps-functions\Profile.ps1"
$dest = "$env:windir\system32\windowspowershell\v1.0\"
$source2 = "\\Cold.grcc.edu\sccm\scripts\PS-Functions\SCCM-Functions.ps1"
$dest2 = "$env:windir\system32\windowspowershell\v1.0\modules\GRCC"

If ( !(Test-path "$dest\profile.ps1") )
    {Write-host "Non-Compliant" }
ElseIf ( Compare-Object (Get-Content -Path "$source") (Get-Content -Path "$dest\profile.ps1") -ea SilentlyContinue )
    {Write-host "Non-Compliant"}
ElseIf ( !(Test-path "$dest2\sccm-functions.ps1" ) )
    {Write-host "Non-Compliant"}
ElseIf ( Compare-Object (Get-Content -Path "$source2") (Get-Content -Path "$dest2\SCCM-Functions.ps1") -ea SilentlyContinue )
    {Write-host "Non-Compliant"}
Else{write-host "Compliant"}