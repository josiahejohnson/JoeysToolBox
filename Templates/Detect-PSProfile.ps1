#Check Powershell Profile
$ErrorActionPreference = "Continue"

$source = "\\Cold.grcc.edu\sccm\scripts\PS-Functions\Profile.ps1"
$dest = "$env:windir\system32\windowspowershell\v1.0\"

If (Test-path "$dest\profile.ps1")
    {
    $netFile = Get-Content -Path "$source"
    $localfile = Get-Content -Path "$dest\profile.ps1"

    If(!(Compare-Object $netFile $localfile)){Write-host "Compliant"}
         Else{Write-host "Non-Compliant"}
    }
Else{write-host "Non-Compliant"}