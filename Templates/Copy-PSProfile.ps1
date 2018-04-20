$ErrorActionPreference = "Continue"

$source = "\\Cold.grcc.edu\sccm\scripts\PS-Functions\Profile.ps1"
$dest = "$env:windir\system32\windowspowershell\v1.0\"

If(Test-Path $dest)
    {
    Copy-Item -Path $source -Destination $dest -Force
    }