#test for OperatingSystem, Macaddress, and Serial.

$Server = "wsusservername"
$Results = "C:\wsusmodels.csv"

[reflection.assembly]::LoadWithPartialName("Microsoft.UpdateServices.Administration") | out-null

if(!$WSUS){
$WSUS = [Microsoft.UpdateServices.Administration.AdminProxy]::GetUpdateServer();
}

$computerScope = New-Object Microsoft.UpdateServices.Administration.ComputerTargetScope
$computers = $WSUS.GetComputerTargets($computerScope)
 
$Computers | Sort-Object Model | Select-Object fulldomainname,operatingsystem,ipaddress,macaddress,make,model,serial | Export-CSV -Path $Results -NoTypeInformation