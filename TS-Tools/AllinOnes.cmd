reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\services\wlansvc" /v "Start" /t reg_dword /d 4 /f


reg.exe add HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Wisp\Touch" /v "TouchGate" /t reg_dword /d 0 /f

exit 0