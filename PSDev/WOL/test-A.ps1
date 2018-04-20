<#
.SYNOPSIS
    A Wake on LAN Script that pulls in computer data from a csv file.
.DESCRIPTION
    This script pulls in computer data from a csv file and sends a Wake on 
    LAN Magic Packet to the specified computer or group of computers.

    The csv (.\computers.csv) file requires the following fields:
        name
        mac
        ip
        type
        active
        nictype
        
    name - the name of the system
    mac - the mac of the system with hex pairs separated with ':' or '-'
    ip - the ipv4 local subnet broadcast address
    type - "Desktop","Laptop","Server",or "Other"
    active - 1 for active, or 0 for inactive
    nictype - "P" for physical, or "W" for wireless NIC
    
    The script can be called by individual system name(s), by groups of
    systems.  Grouping is available by the computer type or subnet ip broadcast.  
    
    The script, by default, selects only the physical NICs.
.PARAMETER Name
    The Name Parameter selects the system names.
.PARAMETER OverrideIP
    The Override IP parameter selects a different ip address to send the magic
    packet to than what is in the csv file.
.PARAMETER ComputerType
    "Desktop","Laptop","Server","Other"
.PARAMETER SubnetBroadcastIP
    Used to select a group of computers based on their subnet's broadcast
    address.
.PARAMETER IncludeWirelessNic
    Includes wireless nics in selection.
.PARAMETER OnlyWirelessNic
    Only returns wireless nics in selection.
.PARAMETER PrintOnly
    PrintOnly will output the systems selected, but will not send the magic
    packet.
.PARAMETER ReturnFileContents
    This will return the file contents in their entirety, including systems
    with blank macs or that are marked as inactive.
.EXAMPLE
PS>wake-system.ps1 -Name SRV1

This will send a magic packet to the mac address of SRV1, assuming that the
mac is valid and SRV1 is marked as active.
.EXAMPLE
PS>wake-system.ps1 -Name SRV1,SRV2,SRV3

This will send a magic packet to SRV1, SRV2, and SRV3
.EXAMPLE
PS>wake-system.ps1 -Name SRV1 -IncludeWirlessNic

This will send a magic packet to SRV1's physical and wireless nic
.EXAMPLE
PS>wake-system.ps1 -Name SRV1 -OnlyWirelessNic

This will send a magic packet to SRV1's wireless nic only.
.EXAMPLE
PS>wake-system.ps1 -ComputerType Desktop

This will send a magic packet to all desktops.
.EXAMPLE
PS>wake-system.ps1 -ComputerType Desktop,Laptop

This will send a magic packet to all desktops and laptops.
.EXAMPLE
PS>wake-system.ps1 -SubnetBroadcastIP 192.168.50.255

This will send a magic packet to all computers with 192.168.50.255 in the 'ip'
field of the csv file.
.EXAMPLE
PS>wake-system.ps1 -ComputerType Desktop -PrintOnly

This will return the systems that have been selected, but will
not send a magic packet.  This allows you to see the selected systems
ahead of time.
.EXAMPLE
PS>wake-system.ps1 -ReturnFileContents

This returns each system in the csv file.  No magic packets are send.
#>
Param(
    [Parameter(Mandatory=$True,
               Position=0,
               ParameterSetName="Individual")]
    [String[]]
    $Name,
    
    [Parameter(ParameterSetName="Individual")]
    [Parameter(ParameterSetName="Group")]
    [String]
    $OverrideIP,
    
    [Parameter(ParameterSetName="Group")]
    [ValidateSet("Desktop","Laptop","Server","Other")]
    [Alias("Type")]
    [String[]]
    $ComputerType,
    
    [Parameter(ParameterSetName="Group")]
    [Alias("Subnet")]
    [String[]]
    $SubnetBroadcastIP,
    
    [Parameter(ParameterSetName="Individual")]
    [Parameter(ParameterSetName="Group")]
    [switch]
    $IncludeWirelessNic,
    
    [Parameter(ParameterSetName="Individual")]
    [Parameter(ParameterSetName="Group")]
    [switch]
    $OnlyWirelessNic,
    
    [Parameter(ParameterSetName="Individual")]
    [Parameter(ParameterSetName="Group")]
    [switch]
    $PrintOnly,
    
    [Parameter(Mandatory=$True,
               ParameterSetName="File")]
    [switch]
    $ReturnFileContents
)

$regex_mac = "^(?:[0-9A-F]{2}[:-]){5}(?:[0-9A-F]{2})$"
$regex_ipv4 = "^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$"

if($OverrideIP -and ($OverrideIP -notmatch $regex_ipv4)){
    Throw "Invalid IP"
}

if($SubnetBroadcastIP -and ($SubnetBroadcastIP -notmatch $regex_ipv4)){
    Throw "Invalid SubnetBroadcastIP"
}

function determineIP {

    Param(
        $set
    )

    foreach($item in $set){

        $item | Add-Member -MemberType NoteProperty -Name ipaddy -Value ""
    
        if($OverrideIP){
            $item.ipaddy = [System.Net.IPAddress]::Parse($OverrideIP)
        }
        elseif(!$item.ip){
            Write-Host "$($item.name) has no ip. Using system broadcast." -BackgroundColor Black -ForegroundColor Red
            Write-Host ""
            $item.ipaddy = [System.Net.IPAddress]::Broadcast
        }
        elseif($item.ip -and ($item.ip -notmatch $regex_ipv4)){
            Write-Host "$($item.name) has invalid ip. Using system broadcast." -BackgroundColor Black -ForegroundColor Red
            Write-Host ""
            $item.ipaddy = [System.Net.IPAddress]::Broadcast
        }
        else{
            $item.ipaddy = [System.Net.IPAddress]::Parse($item.ip)
        }
    }

}

function sendMagicPacket{

    Param(
        $item
    )
    
    if ($item.mac -NotMatch '^([0-9A-F]{2}[:-]){5}([0-9A-F]{2})$') {
        Write-Host "$($item.name) : Mac address must be 6 hex bytes separated by : or -" -BackgroundColor Black -ForegroundColor Red
    } elseif (!$item.ipaddy) {
        Write-Host "$($item.name) : No IP address." -BackgroundColor Black -ForegroundColor Red
    } else {

        $macByte = $item.mac.split('-:') | %{ [byte]('0x' + $_) }
        $packet = [byte[]](,0xFF * 6)
        $packet += $macByte * 16
        
        Write-Host "Sending Magic Packet to $($item.name)."
        Write-Host "$($item.mac) at $($item.ipaddy.toString())"
        
        try{
            $UDPclient = new-Object System.Net.Sockets.UdpClient
            $UDPclient.connect($item.ipaddy,4000)
            [void]$UDPclient.Send($packet, $packet.Length)
            Write-Host "Packet sent."
        } catch {
            Write-Host "An error occurred." -BackgroundColor Black -ForegroundColor Red
        } finally {
            $UDPclient.Close()
        }
    
    }
    Write-Host ""
    
}

$data_file = ".\computers.csv"
$data = Import-CSV $data_file

$NicTypes = @()
$set = @()

if($OnlyWirelessNic){$NicTypes += 'W'}
else{
    $NicTypes += 'P'
    if($IncludeWirelessNic){
        $NicTypes += 'W'
    }
}

echo ""

switch ($psCmdlet.ParameterSetName) {

    "Individual" {
        $set = $data | where {($Name -contains $_.name) -and
                              ($_.active -ne [int]$False) -and
                              ($NicTypes -contains $_.nictype) -and
                              ($_.mac)}
        
        if ($PrintOnly) {
            $set
        } else {
            determineIP $set
            foreach($item in $set){
                sendMagicPacket $item
            }
        }
    }
    
    "Group" {
        $set = $data | where {($_.active -ne [int]$False) -and
                              ($NicTypes -contains $_.nictype) -and
                              ($_.mac)}

        if($ComputerType){
            $set = $set | where {$ComputerType -contains $_.type}
        }
                              
        if($SubnetBroadcastIP){
            $set = $set | where {$SubnetBroadcastIP -contains $_.ip}
        }

        if ($PrintOnly) {
            $set
        } else {
            determineIP $set
            foreach($item in $set){
                sendMagicPacket $item
            }
        }
    }
    
    "File" {
        $data
    }

}