#Check SCCM-Functions
$ErrorActionPreference = "Continue"

$source = "\\Cold.grcc.edu\sccm\scripts\PS-Functions\SCCM-Functions.ps1"
$dest = "$env:windir\system32\windowspowershell\v1.0\modules\GRCC"

If (Test-path "$dest\sccm-functions.ps1")
    {
    $netFile = Get-Content -Path "$source"
    $localfile = Get-Content -Path "$dest\SCCM-functions.ps1"

    IF(!(Compare-Object $netFile $localfile))
            {Write-host "Compliant"}
    Else{Write-host "Non-Compliant"}

    }
Else{write-host "Non-Compliant"}

