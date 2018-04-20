
$ComputerModel = (Get-WmiObject -Class Win32_ComputerSystem | Select-Object Model).Model
$SerialNumber = (Get-WmiObject -Class Win32_BIOS | Select-Object SerialNumber).SerialNumber
 
#Build name and set OSDComputerName Variable for Task Sequence
    $ComputerModel = ($ComputerModel).Substring(0,4)
    IF(($SerialNumber).lenght -gt 9){$SerialNumber = ($SerialNumber).Substring(0,8)}
    $OSDComputerName = $ComputerModel + "-" + $SerialNumber
    $TSEnv = New-Object -COMObject Microsoft.SMS.TSEnvironment
    $TSEnv.Value("OSDComputerName") = "$OSDComputerName"