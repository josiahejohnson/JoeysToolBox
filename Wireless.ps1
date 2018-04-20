
##Disable Active Probing to disable stupid web launch
#New-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\NlaSvc\Parameters\Internet -Name EnableActiveProbing -PropertyType DWORD -Value 0 -Force | Out-Null

$Output += & cmd /c netsh wlan add profile filename="GRCC_Wireless.xml" 
$Output += & cmd /c netsh wlan connect name="GRCC Wireless"

Start-Sleep -Seconds 2

$url = "https://grccwireless.grcc.edu/login.html"

## Build IE Window
$ie = new-object -ComObject "InternetExplorer.Application"
    $ie.ToolBar = $false
    $ie.StatusBar = $false
    $ie.menubar = $false
    $ie.Resizable = $false
    $ie.AddressBar = $false
    #$ie.FullScreen = $true
$ie.Visible = $true
$ie.Navigate($url)

While ($ie.busy -or ($ie.LocationURL -eq "$url")){ Start-Sleep -Seconds 1 }

If($ie.visable)
    {
        $ie.ToolBar = $true
        $ie.StatusBar = $true
        $ie.menubar = $true
        $ie.Resizable = $true
        $ie.AddressBar = $true
    }

## Re-enable Active Probing Because IDK
#New-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\NlaSvc\Parameters\Internet -Name EnableActiveProbing -PropertyType DWORD -Value 1 -Force | Out-Null