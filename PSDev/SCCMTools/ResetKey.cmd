@echo off

NET STOP CCMEXEC
%windir%\ccmsetup\ccmsetup.exe RESETKEYINFORMATION = TRUE