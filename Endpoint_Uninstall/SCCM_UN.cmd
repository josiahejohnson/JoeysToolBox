@echo off

NET STOP CCMEXEC

%windir%\ccmsetup\ccmsetup.exe RESETKEYINFORMATION = TRUE

If EXIST "%SystemRoot%\temp\ccmdelcert.exe" (
"%SystemRoot%\temp\ccmdelcert.exe"
)

If NOT EXIST "%SystemRoot%\temp\ccmdelcert.exe" (
Copy /V /Y \\cold.grcc.edu\sccm\apps\Microsoft\Endpoint_Uninstall\ccmdelcert.exe %SystemRoot%\temp\
"%SystemRoot%\temp\ccmdelcert.exe"
)


If EXIST "%WINDIR%\SMSCFG.ini" (
Del /s /q %WINDIR%\SMSCFG.ini
)

If NOT EXIST "%WINDIR%\CCMSetup\CCMsetup.exe" (
"\\cold.grcc.edu\sccm\apps\Microsoft\Endpoint\ccmsetup.exe" /uninstall
)

If EXIST "%WINDIR%\CCMSetup\CCMsetup.exe" (
"%WINDIR%\ccmsetup\ccmsetup.exe" /uninstall
)


WMIC product WHERE "Name LIKE 'Microsoft%Security%'" call uninstall /nointeractive

WMIC product WHERE "Name LIKE 'Microsoft%Endpoint%'" call uninstall /nointeractive

If EXIST "%SystemRoot%\temp\ccmdelcert.exe" (
"%SystemRoot%\temp\ccmdelcert.exe"
)

If EXIST "%WINDIR%\SMSCFG.ini" (
Del /s /q %WINDIR%\SMSCFG.ini
)

IF EXIST "%WINDIR%\system32\ccm\" (
Del /s /q "%WINDIR%\system32\ccm\"
)

IF EXIST "%WINDIR%\system32\ccmCache\" (
Del /s /q "%WINDIR%\system32\ccmCache\"
)

IF EXIST "%WINDIR%\system32\ccmsetup\" (
Del /s /q "%WINDIR%\system32\ccmsetup\"
)

IF EXIST "HKLM\SOFTWARE\Microsoft\CCM" (
Reg Delete HKLM\SOFTWARE\Microsoft\CCM /f
)

IF EXIST "HKLM\SOFTWARE\Microsoft\CCMSetup" (
Reg Delete HKLM\SOFTWARE\Microsoft\CCMSetup /f
)

IF EXIST "HKLM\SOFTWARE\Microsort\SMS" (
Reg Delete HKLM\SOFTWARE\Microsort\SMS /f
)


