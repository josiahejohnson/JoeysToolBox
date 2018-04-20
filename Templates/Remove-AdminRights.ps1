    $computer = "$env:COMPUTERNAME"
    $group = "Administrators"
    $domain = "AD"
    $Valid = $false

Try{
    $user = "hamiltonn"

    $de = [ADSI]"WinNT://$computer/$Group,group" 
    $de.psbase.Invoke("Remove",([ADSI]"WinNT://$domain/$user").path)

}Catch{$Valid1 = $true}

Try{
    $user = "JohnsonE"

    $de = [ADSI]"WinNT://$computer/$Group,group" 
    $de.psbase.Invoke("Remove",([ADSI]"WinNT://$domain/$user").path)

}Catch{$Valid2 = $true}

Try{
    $user = "dickdavid"

    $de = [ADSI]"WinNT://$computer/$Group,group" 
    $de.psbase.Invoke("Remove",([ADSI]"WinNT://$domain/$user").path)

}Catch{$Valid3 = $true}

If(($Valid1 -eq $true) -and ($Valid1 -eq $true) -and ($Valid1 -eq $true)){ Write-Host "Compliant" }