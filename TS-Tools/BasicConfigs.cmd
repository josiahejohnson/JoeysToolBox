reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /f /v "EnableLUA" /t REG_DWORD /d 0

reg add "HKLM\SYSTEM\CurrentControlSet\services\CSC" /f /v "Start" /t REG_DWORD /d 4

Reg.exe Add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v EnableAutoTray /t REG_DWORD /d 0 /f

Reg.exe Add "HKLM\SOFTWARE\MICROSOFT\WINDOWS\CURRENTVERSION\POLICIES\EXPLORER" /v HIDESCAHEALTH /t REG_DWORD /d 1 /f