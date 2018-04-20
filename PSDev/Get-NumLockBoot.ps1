Function Get-LenovoBIOSSettings {
<#
.SYNOPSIS
Get-LenovoBIOSSettings is a function which acquires all of the bios settings currently configured for any particular lenovo-based computer that is running PowerShell version 4 or greater.

.DESCRIPTION
This Function is inspired by the fact that Lenovo has very poor documentation on how to properly apply bios settings via script.The information used for this function can be found here: http://download.lenovo.com/ibmdl/pub/pc/pccbbs/mobiles_pdf/sb_deploy.pdf

To use this function effectively, follow these steps:
1. First, find a test Lenovo pc.
2. Set the Lenovo Bios back to factory defaults, and then change those bios settings that you would like to deploy.
3. Boot the test pc to windows and run Get-LenovoBIOSSettings. 
4. Now should you have a Log file that has a list of all settings, copy the lines of settings you would like to apply. Each line should be it's own string.
5. In your deployment script, create a list containing those strings of settings and feed that list to Set-BIOSSettings.

Log file(s) available here: 
• \\targetpc\c$\windows\logs\GetLenovoBiosSettings_(DATE).log
• c:\windows\logs\GetLenovoBiosSettings_(DATE).log 
• and\or the host\console window (depending on how you choose to run this function)
By getting the settings from wmi and outputting them to a log file, you can get the proper string to feed into Set-LenovoBIOSSettings for almost any setting regardless of what Lenovo’s documentation says.

The output from Get-LenovoBIOSSettings is not automatically compatible with the $SettingsToBeApplied parameter in the Set-LenovoBIOSSettings function. Instead, this is designed to merely give you all possible settings (in their correct format) that may be configured for any particular model of Lenovo. Once you have the list, pick and choose which settings that you would like to feed to Set-LenovoBiosSettings.

Use: Help Get-LenovoBiosSettings –FULL and Help set-LenovoBiosSettings –FULL to see examples of its usage.

.PARAMETER computername

$Get-LenovoBIOSSettings by default will attempt to acquire the currently applied BIOS settings on the computer that the script is running on. This behavior can be changed by specifying the $ComputerName parameter.


.EXAMPLE
Here is an example on how to acquire a list of properly configured settings from the test Lenovo PC:

Get-LenovoBIOSSettings -ComputerName Some-PC

After Power Loss,Last State;[Optional:Power Off,Power On,Last State]
Alarm Date(MM/DD/YYYY),[01/01/1999][Status:ShowOnly]
Alarm Day of Week,Sunday;[Optional:Sunday,Monday,Tuesday,Wednesday,Thursday,Friday,Saturday][Status:ShowOnly]
Alarm Time(HH:MM:SS),[00:00:00][Status:ShowOnly]
Allow Flashing BIOS to a Previous Version,Yes;[Optional:No,Yes]
Automatic Boot Sequence,Network 1:SATA 1:SATA 2:SATA 3:USB CDROM:USB KEY:USB HDD:eSATA:Other Device:USB FDD
Boot Agent,PXE;[Optional:Disabled,PXE]

...etc, usually there are many settings, and you typically would not want to select them all, just manually select those settings that you would like to configure, that aren't already configured by default.


Then, manually create a list of settings to be used with Set-LenovoBIOSSettings.

$Settings = "Allow Flashing BIOS to a Previous Version,Yes;[Optional:No,Yes]","Boot Agent,PXE;[Optional:Disabled,PXE]","Boot Mode,Auto;[Optional:Auto,UEFI,Legacy]"

Notice that this is a list of strings "","","" In-between each pair of quotes, paste 1 setting. Create any length list desired. 
Now feed the list to Set-LenovoBIOSSettings

Set-LenovoBIOSSettings -ComputerName Some-PC -SettingsToBeApplied $Settings


.EXAMPLE
It is also possible to select particular settings from the output and pipe it to Set-LenovoBIOSSettings. But this is not recommended, unless you already know which strings to select to begin with:

Get-LenovoBIOSSettings -ComputerName Some-PC | Select-String "Wake on Lan" | Set-LenovoBIOSSettings -ComputerName Some-PC

.LINK 
http://download.lenovo.com/ibmdl/pub/pc/pccbbs/mobiles_pdf/sb_deploy.pdf
#>

[CmdletBinding()]
param(
[Parameter(Mandatory=$FALSE, ValueFromPipeline=$true,Position=0)]
[string]$ComputerName = (Get-Content env:computername))

#Defining Write-Log and Create-LogFile within the Function, to make logging easier.
Function Create-LogFile{
[CmdletBinding()]
param([Parameter(Mandatory=$true, ValueFromPipeline=$true,Position=0)]
[string]$LogName,
[Parameter(Mandatory=$false, ValueFromPipeline=$true,Position=1)]
[string]$LogfileVarName = 'LogFile',
[Parameter(Mandatory=$false, ValueFromPipeline=$true,Position=2)]
[string]$LogFileScope = 'Global')

$LogFileString = "c:\windows\logs\$($LogName)_$(get-date -UFormat %m-%d-%y).log"
if (Test-Path $LogFileString){Remove-Item -Path $LogFileString -Force}
Set-Variable -Name $LogfileVarName -Value $LogFileString -Scope $LogFileScope -Force}

Function Write-Log {
[CmdletBinding()]
param(
[Parameter(Mandatory=$false, ValueFromPipeline=$true,Position=0)]
[string]$message,
[Parameter(Mandatory=$false, ValueFromPipeline=$true,Position=1)]
[string]$LogName = "REPLACE",
[Parameter(Mandatory=$false, ValueFromPipeline=$true,Position=2)]
[string]$LogfileVarName = 'LogFile',
[Parameter(Mandatory=$false, ValueFromPipeline=$true,Position=3)]
[string]$LogFileScope = 'Global')

#The Messaging Script Block, to be executed only if $LogFile exists.
$MessageScriptBlock = {
# Call Write-Log followed by a qouted message to log it in the log file and display it on the screen.
#Some output will not display on the host screen, but will display on the log file.
if ($message -eq $null){
Write-Host " "
" "| Out-File -FilePath $LogFile -Force -Append; Return}
if ($message -ne $null) {
$message = "--"+ $message + " - $(Get-Date -Format "hh:mm:ss tt")--"
Write-Host $message
$message | Out-File -FilePath $LogFile -Force -Append}}

if ((Get-Variable $LogfileVarName) -eq $null) {
if ((Get-Command -Name Create-LogFile) -ne $null) {Create-LogFile -LogName $LogName}
else {
Write-Host "There is no log file nor is there a `"Create-LogFile`" Function available"
Write-Host "Creating a Logfile to continue the script: c:\windows\logs\REPLACE.log"
$LogFileString = "c:\windows\logs\REPLACE.log"
if (Test-Path $LogFileString){Remove-Item -Path $LogFileString -Force}
Set-Variable -Name $LogfileVarName -Value $LogFileString -Scope $LogFileScope -Force}}

Invoke-Command -ScriptBlock $MessageScriptBlock}


#Creating the logfile below:
Create-LogFile -LogName GetLenovoBiosSettings


Write-Log "Grabbing the Bios Settings"
Write-Log "Start of Script. Date: $(get-date -UFormat %m-%d-%y)"
Write-Log "The original location of this log file is: $LogFile and this file was run on this computer: $ComputerName"

#Checking PowerShell Version
Write-Log "Here is the current running version of PowerShell:"
$PSVersionTable
#$PSVersionTable | Out-File -FilePath $LogFile -Append

if ($PSVersionTable.PSVersion.Major -lt 4) {Write-Log "Warning, this script has only been tested on PowerShell 4."}
Write-Log
Write-Log


#Checking the ComputerName Parameter, before proceeding.
if (!(Test-Connection $ComputerName -Quiet)) {Write-Log "The computer $ComputerName is not pingable, make sure that it is on.";Break}

#Just making sure that the computer used is a Lenovo. If it's not, Break the script.
if ((Get-WmiObject win32_computersystem -ComputerName $ComputerName).Manufacturer -notmatch "LENOVO") {Write-Log "This computer is not a Lenovo, Breaking now";Break}

#Instantiating an instance of the lenovo_BIOSsetting wmiobject as a variable. This will be an instance of the currently running config of the BIOS as of the execution of this command.
Set-Variable -Name CurrentBIOSSettings -Value (Get-WmiObject lenovo_BIOSsetting -Namespace 'Root\wmi'-ComputerName $ComputerName) -Scope Global

#Grabbing all of the Bios Settings available.
$ALLBiosSettings = $CurrentBiosSettings | Select-Object -ExpandProperty currentsetting | where {$_.length -gt 0} | Sort-Object 
if ($ALLBiosSettings -ne $null) {
Write-Log "Below is all of the Bios Settings gathered from $ComputerName :"
$ALLBiosSettings | Out-File -FilePath $LogFile -Append -Force}
if ($ALLBiosSettings -eq $null) { Write-Log "Something went wrong, there are no Bios Settings available."}

Return $ALLBiosSettings}

$Name = "Boot Up Num-Lock Status"
 Get-LenovoBIOSSettings -OutVariable $output | Select-String $name 
Write-Host $output