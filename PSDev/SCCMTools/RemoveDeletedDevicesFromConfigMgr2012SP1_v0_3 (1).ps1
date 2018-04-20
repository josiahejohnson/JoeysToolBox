#
# Script by         : Peter Daalmans, Configuration Manager MVP (info@configmgrblog.com)
# Script version    : v0.3
# Release date      : 02/18/2014
#
# v0.1 Release date : 01/25/2013
# Description:
#
# This script can be used to delete in Active Directory deleted devices. 
# This script will not delete the discovered Mobile Devices, manual added 
# devices or devices that resides in another domain or workgroup.
#
# How to use it:
#
# Supply the site code, installation drive, location of the log files and the 
# name of the domain. 
#
# $sitecode = "<sitecode>:"
# $sitecode = "PS1:"
# $installdrive = "<ConfigMgr Admin Console installation>"
# $installdrive = "C:"
# $loglocation = "<loglocation>"
# $loglocation = "D:\Logfiles\"
# $localdomain = "<domainname>"
# $localdomain = "ConfigMgrLab"
# $maxdevices = <maximum number of devices in your ConfigMgr environment> 
# $maxdevices = 2000
#
# Check for more Configuration Manager information my blog: http://configmgrblog.com
#
# Create a scheduled task and run a commandline like this: 
# C:\Windows\SysWOW64\WindowsPowerShell\v1.0\powershell.exe e:\Scripts\RemoveDeletedDevicesFromConfigMgr2012SP1.ps1 -ExecutionPolicy Unrestricted
#
# New in v0.2:
#
#        - Ability to set the Maximum Query Result Size of ConfigMgr 2012 SP1, by default this is 1000 items
#        - Fixed little bug while searching in AD for objects give back a number higher than 1. (more AD objects with the same name)
# Fix in v0.3:
#        - Due lack of capitals in properties some device values where not available.
#
# Attention: Always test this script in a representative Lab environment first. 
#            The script is  provided “AS IS” with no warranties.
# 

$sitecode = "GR1:"
$installdrive = "D:"
$loglocation = "C:\Logfiles\"
$localdomain = "AD.GRCC.edu"
$maxdevices = 3000

Function Write-Log{            
##----------------------------------------------------------------------------------------------------            
##  Function: Write-Log            
##  Purpose: This function writes trace32 log fromat file to user desktop      
##  Function by: Kaido Järvemets Configuration Manager MVP (http://www.cm12sdk.net)
##----------------------------------------------------------------------------------------------------                            
PARAM(                     
    [String]$Message,                                  
    [int]$severity,                     
    [string]$component                     
    )                                          
    $TimeZoneBias = Get-WmiObject -Query "Select Bias from Win32_TimeZone"                     
    $Date= Get-Date -Format "HH:mm:ss.fff"                     
    $Date2= Get-Date -Format "MM-dd-yyyy"                     
    $type=1                         
    
    "<![LOG[$Message]LOG]!><time=$([char]34)$date+$($TimeZoneBias.bias)$([char]34) date=$([char]34)$date2$([char]34) component=$([char]34)$component$([char]34) context=$([char]34)$([char]34) type=$([char]34)$severity$([char]34) thread=$([char]34)$([char]34) file=$([char]34)$([char]34)>"| Out-File -FilePath "$loglocation\Deleted-Devices-$Date2.Log" -Append -NoClobber -Encoding default            
    }   

Import-Module ActiveDirectory

IF(test-path ($installdrive + "\Program Files (x86)\Microsoft Configuration Manager\AdminConsole\bin")) {
    Import-Module ($installdrive + "\Program Files (x86)\Microsoft Configuration Manager\AdminConsole\bin\ConfigurationManager.psd1")
}
ELSE
{IF(test-path ($installdrive + "\Program Files\Microsoft Configuration Manager\AdminConsole\bin")){
    Import-Module ($installdrive + "\Program Files\Microsoft Configuration Manager\AdminConsole\bin\ConfigurationManager.psd1")
    }
    ELSE
    {
    Write-Log -Message "ConfigMgr 2012 SP1 Admin console not found!" -severity 1 -component "Error"
    }
}
Set-Location $sitecode
Set-CMQueryResultMaximum -Maximum $maxdevices
$Computers = Get-CMDevice -CollectionName "All Systems" | ForEach-Object {$_.Name}
Set-Location AD:
for( $n = 0; $n -le $Computers.count -1; $n++ ) {
    IF(( $Computers[$n] -ne "x64 Unknown Computer (x64 Unknown Computer)" ) -And ($Computers[$n] -ne "x86 Unknown Computer (x86 Unknown Computer)")) {
        $comp = $Computers[$n] 
        $comp = $comp.ToUpper() 
        $searcher = ([adsisearcher]"samAccountName=$comp*")
        $rtn = $searcher.FindAll()
        IF($rtn.count -eq 0)  { 
            Set-Location $sitecode
            $tempdom = Get-CMDevice -name $Computers[$n] | ForEach-Object {$_.Domain}
            $resourcetype = Get-CMDevice -name $Computers[$n] | ForEach-Object {$_.ResourceType}
            $devicetype = Get-CMDevice -name $Computers[$n] | ForEach-Object {$_.DeviceType}
            if (($tempdom -eq $localdomain) -And  ($resourcetype -eq "5") -And ($devicetype -eq $null) ){
                Write-Log -Message "Deleting device from ConfigMgr 2012 - $Comp deleted" -severity 3 -component "Cleanup"
#                Remove-CMDevice -name $comp -force 
                }
            ELSE
            {
                IF(($tempdom -ne $localdomain) -And ($tempdom -ne $null) -And ($devicetype -eq $null)) { Write-Log -Message "Preserving device in ConfigMgr 2012 - $Comp not deleted, member of other domain or workgroup." -severity 1 -component "Cleanup"}
                IF(($tempdom -eq $null) -And ($devicetype -eq $null)) { Write-Log -Message "Preserving device in ConfigMgr 2012 - $Comp not deleted, manually added or mobile device." -severity 1 -component "Cleanup"}
                IF($devicetype -ne $null) { Write-Log -Message "Preserving device in ConfigMgr 2012 - $Comp not deleted, mobile device." -severity 1 -component "Cleanup"}

            }
       }
    }
}
