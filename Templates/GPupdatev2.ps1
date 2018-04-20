## GPUpdate SCCM Script 
## Version 2

$result = Invoke-Command -ScriptBlock {& gpupdate /force} | Where {$_}

If(($result[1] -match "Successfully") -and ($result[2] -match "Successfully"))
    {
        Write-host "Group Policy Updated Successfully"
        exit 0
    }
ElseIf(!($result[1] -match "Successfully") -and ($result[2] -match "Successfully"))
    {
        Write-host "Computer Policy Failed"
        exit 10
    }
ElseIf(($result[1] -match "Successfully") -and !($result[2] -match "Successfully"))
    {
        Write-host "User Policy Failed"
        exit 11
    }
Else
    {
        Write-Host $result
        exit 1    
    }