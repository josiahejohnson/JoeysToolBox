$Result = (GWMI win32_product -filter "Name Like 'MasterCAM%%7%%'")
If ($Result) { Write-Host $true }