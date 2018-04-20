$netAdapter = Get-WmiObject -Class Win32_NetworkAdapterConfiguration -Filter "IPEnabled=TRUE"

Try{
$netAdapter | Foreach-Object{ $_.SetWINSServer('','') } -ErrorAction stop | Out-null
}Catch{Write-Host $Error.exception.Message}
Try{
$netAdapter | Foreach-Object{ $_.SetDynamicDNSRegistration($true) } -ErrorAction stop | Out-null
}Catch{Write-Host $Error.exception.Message}
Try{
$netAdapter | Foreach-Object{ $_.SetDNSDomain('grcc.edu') } -ErrorAction stop | Out-null
}Catch{Write-Host $Error.exception.Message}
Try{
Get-NetAdapter | Disable-NetAdapterBinding -ComponentID ms_tcpip6 -ErrorAction Stop | Out-null
}Catch{Write-Host $Error.exception.Message}


Foreach($n in $netAdapter)
    {
    If(($n | Select WINS).winsPrimaryServer -ne $null)
        {Write-host "WINS Server is still set on connection: $($n.Name)"}
    ElseIF(($n | Select DNS).FullDNSRegistrationEnabled -ne $true)
        {Write-host "DNS Registration not set on connection: $($n.name)"}
}

foreach($n in Get-NetAdapter -Physical)
    {
      If( ($n | Get-NetAdapterBinding -ComponentID ms_tcpip6).enabled )
        {Write-host "IPv6 still enabled on connection: $($n.name)"}
    }