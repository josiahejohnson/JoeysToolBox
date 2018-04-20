If((Test-Path "$env:windir\sun\java\deployment") -and (Test-Path "$env:windir\sun\java\deployment\deployment.config") -and (Test-Path "$env:windir\sun\java\deployment\deployment.properties") -and (Test-Path "$env:windir\sun\java\deployment\exception.sites"))
    {Write-Host "Compliant"}
Else{Write-Host "Non-Compliant"}