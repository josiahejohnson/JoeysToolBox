@echo off

type %systemroot%\smscfg.ini

del /s /f %systemroot%\smscfg.ini

\\cold.grcc.edu\sccm\apps\microsoft\endpoint_uninstall\ccmdelcert.exe

net stop ccmexec

net start ccmexec

ping localhost -n 10

type %systemroot%\smscfg.ini

IF EXIST %systemroot%\smscfg.ini (exit 0) ELSE (exit 1)