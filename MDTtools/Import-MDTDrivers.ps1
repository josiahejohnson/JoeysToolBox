<#
.SYNOPSIS
Imports Windows Drivers into Microsoft Deployment Toolkit.
.DESCRIPTION
The Import-MDTDrivers.ps1 script will duplicate a folder tree structure in Microsoft Deployment Toolkit and import the Drivers.
.PARAMETER $DriverPath
The fully qualified path to the folder that contains the device drivers you want to import. example: "C:\Downloads\Drivers". The default is the current folder in the shell.
.PARAMETER PSDriveName
(Optional) MDT Persistent drive name example: "DS002". The default is the Persistent drive of the first Deployment Share.
.PARAMETER DeploymentShare
(Optional) MDT Persistent drive path example: "D:\Depshare". The default is the first Deployment Share.
.EXAMPLE
Import-MDTDrivers.ps1
This will import drivers from the current location to the driverstore of the first detected deploymentshare replicating the tree structure.
.EXAMPLE
Import-MDTDrivers.ps1 -DriverPath C:\Downloads\Drivers -PSDriveName DS001 -DeploymentShare D:\DeploymentShare
This will import the device drivers into MDT from the source folder C:\Downloads\Drivers to the deployment share DS001 located at D:\DeploymentShare
.NOTES
Author: Andrew Barnes
Date: 4 June 2012
Last Modified: 23 July 2012
.LINK
https://scriptimus.wordpress.com/2012/06/18/mdt-powershell-importing-drivers/
#>
Param (
    [String]$DriverPath = $PWD,                 # Device drivers path example: "C:\Downloads\Drivers"
    [String]$PSDriveName,       # MDT Persistent drive name example: "DS002"
    [String]$DeploymentShare = "\\cold.grcc.edu\MDT\DeploymentShare"   # MDT Persistent drive path example: "D:\Depshare"
)
 
# \\ Import MDT Module
Import-Module "C:\Program Files\Microsoft Deployment Toolkit\bin\MicrosoftDeploymentToolkit.psd1"
 
# \\ Detect First MDT PSDrive
IF (!$PSDriveName) {$PSDriveName = (Get-MDTPersistentDrive)[0].name}
 
# \\ Detect First MDT Deployment Share
IF (!$DeploymentShare) {$DeploymentShare = (Get-MDTPersistentDrive)[0].path}
 
    $DSDriverPath = $PSDriveName+':\Out-of-Box Drivers'
    $DSSelectionProfilePath = $PSDriveName+':\Selection Profiles'
 
# \\ Connect to Deployment Share
If (!(Get-PSDrive -Name $PSDriveName -ErrorAction SilentlyContinue)) {
    New-PSDrive -Name $PSDriveName -PSProvider MDTProvider -Root $DeploymentShare
        }
# \\ Loop through folders and import Drivers
Get-ChildItem $DriverPath | foreach {
    $OS = $_
    if (!(Test-Path $DSDriverPath\$OS)) {
        new-item -path $DSDriverPath -enable "True" -Name $OS -ItemType "folder" -Verbose
        }
 
    if (!(Test-Path $DSSelectionProfilePath"\Drivers - "$OS)) {
        new-item -path $DSSelectionProfilePath -enable "True" -Name "Drivers - $OS" -Definition "<SelectionProfile><Include path=`"Out-of-Box Drivers\$OS`" /></SelectionProfile>" -ReadOnly "False" -Verbose
        }
 
    Get-ChildItem $_.FullName | foreach {
        $Make = $_
        if (!(Test-Path $DSDriverPath\$OS\$Make)) {
            new-item -path $DSDriverPath\$OS -enable "True" -Name $Make -ItemType "folder" -Verbose
            }
        Get-ChildItem $_.FullName | foreach {
            $Model = $_
            if (!(Test-Path $DSDriverPath\$OS\$Make\$Model)) {
                new-item -path $DSDriverPath\$OS\$Make -enable "True" -Name $Model -ItemType "folder" -Verbose
                import-mdtdriver -path $DSDriverPath\$OS\$Make\$Model -SourcePath $_.FullName -Verbose
                    }
                }
            }
        }