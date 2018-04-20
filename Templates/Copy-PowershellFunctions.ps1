$source = "\\cold.grcc.edu\sccm\scripts\ps-functions\Profile.ps1"
$dest = "$env:windir\system32\windowspowershell\v1.0\"

If (Test-Path $source -ea SilentlyContinue)
    {
    If ( !(Test-path "$dest\profile.ps1" -ea SilentlyContinue) )
        { Copy-Item -Path $source -Destination $dest -Force }
    ElseIf ( Compare-Object (Get-Content -Path "$source") (Get-Content -Path "$dest\profile.ps1") -ea SilentlyContinue )
        { Copy-Item -Path $source -Destination $dest -Force }
    Else{ $profile = $true }
    }

$source2 = "\\Cold.grcc.edu\sccm\scripts\PS-Functions\SCCM-Functions.ps1"
$dest2 = "$env:windir\system32\windowspowershell\v1.0\modules\GRCC"

If (Test-Path $source2 -ea SilentlyContinue)
    {
    If ( !(Test-path "$dest2\sccm-functions.ps1" -ea SilentlyContinue ) )
        {
        If( !(Test-Path $dest2 ) ){ New-Item -ItemType 'Directory' -Force -Path $dest2 }
        Copy-Item -Path $source2 -Destination $dest2 -Force
        }
    ElseIf ( Compare-Object (Get-Content -Path "$source2") (Get-Content -Path "$dest2\SCCM-Functions.ps1") -ea SilentlyContinue )
        { Copy-Item -Path $source2 -Destination $dest2 -Force }
    Else{ $funk = $true }
    }


If( ($profile) -and ($funk) ) { write-host "Compliant" }