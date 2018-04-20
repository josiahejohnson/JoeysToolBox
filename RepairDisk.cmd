@echo off

fsutil dirty set %systemdrive%
echo y | chkdsk /r %systemdisk%
sfc /scannow

exit 0