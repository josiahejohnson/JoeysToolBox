$Server = "wsus1.grcc.edu"
$Results = "C:\Users\Public\Desktop\WSUS_Comp_Models.csv"

[reflection.assembly]::LoadWithPartialName("Microsoft.UpdateServices.Administration") | out-null

if(!$wsus) {
	$WSUS = [Microsoft.UpdateServices.Administration.AdminProxy]::GetUpdateServer();
}

$computerScope = New-Object Microsoft.UpdateServices.Administration.ComputerTargetScope
$computers = $WSUS.GetComputerTargets($computerScope)
 
$Computers | Sort-Object Model | Select-Object fulldomainname,ipaddress,make,model | Export-CSV -Path $Results -NoTypeInformation