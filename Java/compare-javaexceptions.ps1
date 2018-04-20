$localfile = get-content -path "$env:windir\sun\java\deployment\exception.sites"
$networkfile = get-content -path "\\cold.grcc.edu\SCCM\Scripts\Prod\Java\Deployment\exception.sites"

If (Compare-Object $networkfile $localfile){Write-Host "Non-Compliant"}
Else{Write-Host "Compliant"}

