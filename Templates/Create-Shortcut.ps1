    #declare shortcut variables
$Name = "Aleks.lnk"
$destination = "$env:public\desktop\$name"
$source = "$env:programfiles\Internet Explorer\iexplore.exe"
$aruments = "-k https://www.aleks.com"
$working = "$env:programfiles\Internet Explorer"
$icon = "\\cold.grcc.edu\SCCM\Settings\Shortcuts\Aleks\mcgrawhill-logo.ico"

if(!(Test-Path $destination))
{
try{
        #build Shortcut
    $Shell = New-Object -comObject WScript.Shell
    $Shortcut = $Shell.CreateShortcut($destination)
    $Shortcut.TargetPath = "$source"
    $Shortcut.Arguments = "$aruments"
    $shortcut.WorkingDirectory = $working
    $Shortcut.WindowStyle = "3"
    If($icon){ $Shortcut.IconLocation = $icon }
    $Shortcut.Save()
    exit 0
    }
    Catch{
    write-host $Error
    exit 1
    }
}
else{exit -1}