@echo off

IF EXIST "%ProgramFiles(x86)%\Lenovo Battery Utility 2015\LenovoBatteryDiagnosticsTool.exe" (
"%ProgramFiles(x86)%\Lenovo Battery Utility 2015\LenovoBatteryDiagnosticsTool.exe"
exit 0
)

IF NOT EXIT "%ProgramFiles(x86)%\Lenovo Battery Utility 2015\LenovoBatteryDiagnosticsTool.exe" (
"%ProgramFiles%\Lenovo Battery Utility 2015\LenovoBatteryDiagnosticsTool.exe"
exit 0
)

"\\cold.grcc.edu\SCCM\Apps\Lenovo\Batterycheck\LenovoBattery.exe" /VERYSILENT /SUPPRESSMSGBOXES /NORESTART /NOCLOSEAPPLICATIONS /NOICONS

exit 0