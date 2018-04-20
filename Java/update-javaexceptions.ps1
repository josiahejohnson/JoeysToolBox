$source = "\\cold.grcc.edu\SCCM\Scripts\Prod\Java\Deployment"
$destination = "$env:windir\sun\java\deployment\"

IF(Test-Path "$env:windir\sun\java\deployment")
    {Copy-Item -Path "$source\exception.sites" -Destination $destination -Force}

$localfile = Get-Content -Path "$env:windir\sun\java\deployment\exception.sites"
$networkfile = Get-Content -Path "$source\exception.sites"

If (Compare-Object $networkfile $localfile){Write-Host "Non-Compliant"}
Else{Write-Host "Compliant"}
