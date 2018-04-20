$source = "\\cold.grcc.edu\SCCM\Scripts\Prod\Java\Deployment"
$destination = "$env:windir\sun\java\deployment\"

Try{
    If((Test-Path "$env:windir\sun\java\deployment") -ne $true)
        {New-Item -ItemType Directory -Force -Path $destination}
    IF((Test-Path "$env:windir\sun\java\deployment\deployment.config") -ne $true)
        {Copy-Item -Path "$source\deployment.config" -Destination $destination -Force}
    IF((Test-Path "$env:windir\sun\java\deployment\deployment.properties") -ne $true)
        {Copy-Item -Path "$source\deployment.properties" -Destination $destination -Force}
    IF((Test-Path "$env:windir\sun\java\deployment\exception.sites") -ne $true)
        {Copy-Item -Path "$source\exception.sites" -Destination $destination -Force}
    Else{Write-Host "Compliant"}


}Catch{write-host $Error}