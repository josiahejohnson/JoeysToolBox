net stop winmgmt /y
  c:
  cd %systemroot%\system32\wbem
  if exist %systemroot%\system32\wbem\repository.old  rmdir /s /q repository.old
  rename %systemroot%\system32\wbem\repository repository.old
  for /f %%s in ('dir /b *.dll') do regsvr32 /s %%s
  for /f %%s in ('dir /b *.mof') do mofcomp %%s
  for /f %%s in ('dir /b *.mfl') do mofcomp %%s
  net start winmgmt
  wmiprvse /regserver

 net stop winmgmt /y
 c:
 cd %systemroot%\system32\wbem
 if exist %systemroot%\system32\wbem\repository.old  rmdir /s /q repository.old
 rename %systemroot%\system32\wbem\repository repository.old


 regsvr32 /s %systemroot%\system32\scecli.dll
 regsvr32 /s %systemroot%\system32\userenv.dll


 mofcomp cimwin32.mof
 mofcomp cimwin32.mfl
 mofcomp rsop.mof
 mofcomp rsop.mfl


 for /f %%s in ('dir /b *.dll') do regsvr32 /s %%s
 for /f %%s in ('dir /b *.mof') do mofcomp %%s
 for /f %%s in ('dir /b *.mfl') do mofcomp %%s


 %systemroot%\system32\wbem\winmgmt /clearadap
 %systemroot%\system32\wbem\winmgmt /kill
 %systemroot%\system32\wbem\winmgmt /unregserver
 %systemroot%\system32\wbem\winmgmt /regserver
 %systemroot%\system32\wbem\winmgmt /resyncperf