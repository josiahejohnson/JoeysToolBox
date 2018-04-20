function send-wakeonlan{
param(
[string]$mac)
if (!($mac -like "*:*:*:*:*") -or ($mac -like "*-*-*-*-*")){
write-error "mac address not in correct format"
break
}

$string=@($mac.split(":""-") | foreach {$_.insert(0,"0x")})
$target = [byte[]]($string[0], $string[1], $string[2], $string[3], $string[4], $string[5])

$UDPclient = new-Object System.Net.Sockets.UdpClient
$UDPclient.Connect(([System.Net.IPAddress]::Broadcast),4000)
$packet = [byte[]](,0xFF * 102)
6..101 |% { $packet[$_] = $target[($_%6)]}
$UDPclient.Send($packet, $packet.Length) | out-null
}
[/sourcecode]

The usage of this function is below:

send-wakeonlan -mac “3C:4A:92:77:AA:21?

send-wakeonlan -mac “3C-4A-92-77-AA-21?