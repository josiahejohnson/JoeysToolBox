@echo off

type %systemroot%\smscfg.ini

del /s /f %systemroot%\smscfg.ini

\\cold.grcc.edu\sccm\apps\microsoft\endpoint_uninstall\ccmdelcert.exe

net stop ccmexec

%WINDIR%\system32\sysprep\sysprep.exe /quiet /generalize /shutdown