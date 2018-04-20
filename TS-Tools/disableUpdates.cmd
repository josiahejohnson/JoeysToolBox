reg.exe add "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "NoAutoUpdate" /t /REG_DWORD /d 1 /f

reg.exe add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\WindowsUpdate" /v "DisableWindowsUpdateAccess" /t /REG_DWORD /d 1 /f

reg.exe add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "NoWindowsUpdate" /t /REG_DWORD /d 1 /f

reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\Internet Communication Management\Internet Communication" /v "DisableWindowsUpdateAccess" /t /REG_DWORD /d 1 /f

exit 0
