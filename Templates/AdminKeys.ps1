
$regKey = "HKLM:\SOFTWARE\GRCC\Admin"
$LastVersion = "April16"
$Expired = ( Get-Date ).AddDays(-120)

If( !(Test-path $regKey))
    { Write-Host "Uncompliant" }
ElseIf( (Get-ItemProperty -Path $regkey).version -notmatch $LastVersion)
    { Write-Host "Uncompliant" }
ElseIf( (Get-ItemProperty -Path $regkey).Changed -le $Expired )
    { Write-Host "Uncompliant" }
Else
    { Write-Host "Compliant" }