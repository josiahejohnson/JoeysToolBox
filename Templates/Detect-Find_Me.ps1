$Find_MeS = gwmi win32_printer | Where {$_.SystemName -match "Papercut"}

If (
    ($Find_MeS.Name -match '\\\\papercut\\Find_Me_BW') -and 
    ($Find_MeS.Name -match '\\\\papercut\\Find_Me_Color')
    )
    
    {write-host $true}
Else
    {Write-host $false}