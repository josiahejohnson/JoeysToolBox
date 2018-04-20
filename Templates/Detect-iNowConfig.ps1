$arc = gwmi win32_operatingsystem | Select OSArchitecture

If($arc -match "64-bit"){$file = "${env:ProgramFiles(x86)}\ImageNow6"}
    Else{$file = "$env:ProgramFiles\ImageNow6"}

If( (Test-path "$file\imagenow.ini") -and (Test-Path "$file\etc\inowprint.ini") )
    {
    $Content = Get-Content "$file\imagenow.ini"
    $Prod = "Production=inowprod01.ad.grcc.edu, 1, 6000, ,0,0,1238014572_933227004500,"
    If($Content.Contains($Prod)){ Write-Host $true }
    }