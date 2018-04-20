#Check SCCM-Functions
$ErrorActionPreference = "Continue"

$source = "\\Cold.grcc.edu\sccm\scripts\PS-Functions\SCCM-Functions.ps1"
$dest = "$env:windir\system32\windowspowershell\v1.0\modules\GRCC"

If( !(Test-Path $dest ) )
    { New-Item -ItemType Directory -Force -Path $dest }
IF( !(Test-Path "$dest\sccm-functions.ps1" ) )
    { Copy-Item -Path $source -Destination $dest -Force }
If(Test-Path "$dest\sccm-functions.ps1" )
    {
    $netFile = Get-Content -Path "$source"
    $localfile = Get-Content -Path "$dest\SCCM-functions.ps1"
        If( Compare-Object $netFile $localfile  )
            { Copy-Item -Path $source -Destination $dest -Force }
    }