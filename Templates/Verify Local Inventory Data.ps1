## Verify Local Inventory Data
## Vesion 1

$CN = $env:COMPUTERNAME
$SE = gwmi win32_SystemEnclosure | Select SMBIOSAssetTag,SerialNumber
$CS = gwmi win32_computersystem | Select Manufacturer,Model,ChassisSKUNumber

$Asset = $SE.SMBIOSAssetTag 
$SN = $SE.SerialNumber

$make = $cs.Manufacturer
$model = $cs.Model
$type = $cs.ChassisSKUNumber


Write-host "Name=$($CN), Asset=$($Asset), Serial=$($SN), Make=$($make), Model=$($model), Type=$($type)"

