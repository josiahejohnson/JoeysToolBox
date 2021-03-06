# This script checks for the user installed version of Chrome. If present bookmarks are copied to the user HomeDirectory on the network and chrome is then removed from the system.

$Path = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Bookmarks"
$HomeDir = "\\storage\homedir\$env:USERNAME"

if(!(Test-Path -Path $Path))
{
    return
    }
else
{
    Copy-Item $Path "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\BookmarksBAK"
    $BmarksBAK = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\BookmarksBAK"
    #$fileObj = $BmarksBAK
    $DateStamp = Get-Date -uformat "%Y-%m-%d@%H-%M-%S"
    #$fileName = $fileObj.Name
    Rename-Item "$BmarksBAK" "$BmarksBAK-$DateStamp"
    $BmarksBAK = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\BookmarksBAK*"
    Copy-Item $BmarksBAK $HomeDir
    Start-Sleep -s 5
    }
    
 $GoogleProf = "$env:LOCALAPPDATA\Google"
 if(!(Test-Path -Path $GoogleProf))
 {
    return
    }
    else
{
   $regkeypath = "hkcu:\Software\Google\Update"
   #$vaule = (Get-Item $regkeypath).test -eq $null
    if(!(Test-Path -Path $regkeypath))
    {
        return
        }
        else
    {
        Remove-Item -path "hkcu:\Software\Google" -Recurse -force
        } 
   #& "$GoogleProf\Chrome\Application\31.0.1650.63\Installer\setup.exe" '--uninstall --force --chrome-sxs'
   #Start-Sleep -s 60
   Stop-Process -processname chrome*
   Remove-Item $GoogleProf -Recurse -force
   if(!(Test-Path -Path "$env:USERPROFILE\Desktop\Google CHrome.lnk")
   {
    break
    {
    else
    }
    Remove-Item -Path "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Google Chrome" -Recurse -force
    Remove-Item -Path "$env:USERPROFILE\Desktop\Google CHrome.lnk" -force
}

Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Restricted -force
exit
