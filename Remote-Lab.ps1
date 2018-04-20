$Lab = "atc229"
$img = "A"
$start = 1
$end = 25
$cns = $start..$end | ForEach-Object {$_.tostring("000")} | % {"L$($Lab)$($img)$($_)"}

$creds = Get-Credential


$user = $creds.UserName
$password = $creds.getNetworkCredential().Password

foreach($cn in $cns)
    {
        Try
            { 
                & cmdkey /generic:TERMSRV/$($cn) /user:$($user) /pass:$($password) 
                & "$env:systemroot\system32\mstsc.exe" /v:$($cn) /noconsentprompt /control
                Start-Sleep -Seconds 3
            }
        Catch{Write-Host $error[0].Exception.Message}
    }