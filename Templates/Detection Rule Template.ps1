<#	
	Created on:   	4/3/2015 1:06 PM
	Created by:   	johnsonj	
	.DESCRIPTION	Compliance rule
	.OUTPUTS		Compliant or Non-Compliant
#>
#Set Compliance Flag
$Compliance = $true

#Add code for complance rule here
#Example
$Example = gwmi win32_computersystem | Select Manufacturer
If ($Example -inotmatch "LENOVO") { $Compliance = $false }

#Write-host Compliance Flag
If ($Compliance) { Write-Host "Compliant" }
If (!($Compliance)) { Write-Host "Non-Compliant" }