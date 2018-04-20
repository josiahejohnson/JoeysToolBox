Function Set-LenovoBIOSSettings {
    <#
.SYNOPSIS

Set Lenovo BIOS Settings
(Set-LenovoBIOSSettings) is a function which can set bios settings for any particular lenovo-based computer which is running PowerShell version 4 or greater.


.DESCRIPTION

Set-LenovoBIOSSettings by default will attempt to apply BIOS settings on the computer the script is running on. This behavior can be changed by specifying the $ComputerName parameter.The $SettingsToBeApplied parameter must take in either a string, or a list of strings. The strings that you apply to the $SettingsToBeApplied parameter must be very specific in order for the Lenovo wmi objects to accept them. That is why there is the Get-LenovoBIOSSettings helper function. You feed some of the output from Get-LenovoBIOSSettings to Set_LenovoBIOSSettings. More information in the help section of Get_LenovoBIOSSettings.


.PARAMETER computername

$ComputerName specifies which computer you would like  to alter in terms of BIOS settings.

.PARAMETER SettingsToBeApplied

$SettingsToBeApplied specifies the settings that should be applied. To get correct settings\format of the settings, please see the full help section in Get-LenovoBIOSSettings.



.EXAMPLE
Here is an example of specifying only one setting:
Set-LenovoBIOSSettings -ComputerName Some-PC -SettingsToBeApplied "Boot Agent,PXE;[Optional:Disabled,PXE]"

.EXAMPLE
Here is an example of specifying a list of settings, which is most likely what you are going to be doing:
Set-LenovoBIOSSettings -ComputerName Some-PC -SettingsToBeApplied "Boot Agent,PXE;[Optional:Disabled,PXE]","Boot Mode,Auto;[Optional:Auto,UEFI,Legacy]","Allow Flashing BIOS to a Previous Version,No;[Optional:No,Yes]"

.EXAMPLE
Obviously you can save the list of settings as a variable and then feed that variable to the function which makes it easier to read:

$Settings = "Boot Agent,PXE;[Optional:Disabled,PXE]","Boot Mode,Auto;[Optional:Auto,UEFI,Legacy]","Allow Flashing BIOS to a Previous Version,No;[Optional:No,Yes]"

Set-LenovoBIOSSettings -ComputerName Some-PC -SettingsToBeApplied $Settings

.LINK
http://download.lenovo.com/ibmdl/pub/pc/pccbbs/mobiles_pdf/sb_deploy.pdf
https://adameyob.com/2014/11/deploy-lenovo-bios-settings/ ‎
#>

[CmdletBinding()]
    param(
    [Parameter(Mandatory=$false, ValueFromPipeline=$true,Position=0)]
    [string]$ComputerName = (Get-Content env:computername),
    [Parameter(Mandatory=$false, ValueFromPipeline=$true,Position=1)]
    $SettingsToBeApplied)



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
    if ($message.Length -eq 0){
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
Create-LogFile -LogName SetLenovoBiosSettings

Write-Log "Updating the Bios Settings"
Write-Log "Start of Script. Date: $(get-date -UFormat %m-%d-%y)"
Write-Log "The original location of this log file is: $LogFile and this file was run on this computer: $ComputerName"

#Checking PowerShell Version
Write-Log "Here is the current running version of PowerShell:"
$PSVersionTable
#$PSVersionTable | Out-File -FilePath $LogFile -Append

if ($PSVersionTable.PSVersion.Major -lt 4) {Write-Log "Warning, this script has only been tested on PowerShell 4."}
Write-Log
Write-Log
Write-Log "Here is the input parameter: `$SettingsToBeApplied: `"$SettingsToBeApplied`""


#Checking the ComputerName Parameter, before proceeding.
if (!(Test-Connection $ComputerName -Quiet)) {Write-Log "The computer $ComputerName is not pingable, make sure that it is on.";Break}

#Just making sure that the computer used is a Lenovo. If it's not, Break the script.
if ((Get-WmiObject win32_computersystem -ComputerName $ComputerName).Manufacturer -notmatch "LENOVO") {Write-Log "This computer is not a Lenovo, Breaking now";Break}

#Instantiating an instance of the lenovo_BIOSsetting wmiobject as a variable. This will be an instance of the currently running config of the BIOS.
Set-Variable -Name CurrentBIOSSettings -Value (Get-WmiObject lenovo_BIOSsetting -Namespace 'Root\wmi'-ComputerName $ComputerName) -Scope Global

#This allows us to declare\set BIOS settings on an instance of the lenovo_setBIOSsetting wmi object, which can later be applied\saved to the BIOS.
if ((Get-Variable -Name BIOSSettings) -eq $null) {Set-Variable -Name BIOSSettings -Value (Get-WmiObject lenovo_setBIOSsetting -namespace root\wmi -ComputerName $ComputerName) -Scope Global}

Write-Log "There is a total of $($SettingsToBeApplied.Count) setting(s) to be configured:"
$index = 1
Write-Log
Write-Log

$SetBIOSSettingScriptBlock = {
    param([string]$SettingToBeApplied)
    
    <# 
        $SetBIOSSettingScriptBlock is defined to apply only one Bios Setting at a time. But because the parent Set_LenovoBIOSSettings function is designed to handle both single Settings,
    and lists of settings, this script block will be used later on in an if\else block where this script block will be used normally for a single setting, but will be used in a
    foreach loop in case the function is fed a list of settings\strings.
    
    #>


    #Grabbing the Setting Name from the string which contains both the value and the name to make querying simpler, as we do not know what the value currently is.
    $SettingName = $SettingToBeApplied.split(",")[0]
    Write-Log
    Write-Log
    Write-Log
    Write-Log
    Write-Log "$index. Configuring $SettingName"
    Set-Variable -Name index -Value ($index += 1) -Scope 1
    
    #Saving the value currently applied to this BIOS setting to a variable for easier use.
    $CurrentBIOSSetting = $CurrentBIOSSettings | where {($_.currentsetting).split(",")[0] -eq $SettingName} | Select-Object -Property CurrentSetting

    #Checking the $SettingToBeApplied parameter.
    Write-Log "Checking the `$SettingName variable, which is: `"$SettingName`", to make sure that the setting exists in the BIOS."
    if ($CurrentBIOSSetting -eq $null) {Write-Log "The BIOS does not contain $SettingName as one of it's configurable BIOS Settings.";Return}

    #Logging the current value for this setting.
    Write-Log "Here is the currently running configuration for this setting:"
    $CurrentBIOSSetting | Out-File -FilePath $LogFile -Append -Force
 
    #If the CurrentBIOSSetting is different than what we want it to be, 
    if ($CurrentBIOSSetting.CurrentSetting -ne $SettingToBeApplied) {
        Write-Log "Trying to apply the Setting: $SettingToBeApplied now."
        $SuccessCode = $BIOSSettings.SetBIOSSetting($SettingToBeApplied).return
        
        #If the setting does not apply to this machine, or if the values are not correctly specified, then the success code would be equivalent to "Invalid Parameter".
        if ($SuccessCode -eq "Invalid Parameter") {Write-Log "The setting: `"$SettingToBeApplied`" is not properly configured for this Machine\BIOS version."}
        
        #If the setting applied successfully, the success code would be equivalent to "Success"
        elseif ($SuccessCode -eq "Success") {
            Write-Log "Successfully applied the setting, below is the newly configured value for this particluar setting:"
            
            #Grabing the latest instance of the BIOS setting object to log it's new value for confirmation\troubleshooting.
            Get-WmiObject lenovo_BIOSsetting -Namespace 'Root\wmi' -ComputerName $ComputerName | where {$($_.CurrentSetting.split(',')[0]) -eq $SettingName} | Select-Object -Property CurrentSetting | Out-File -FilePath $LogFile -Append}}
    
    #If the setting to be applied is the same as the current running config of the bios, log it.
    if ($CurrentBIOSSetting.CurrentSetting -eq $SettingToBeApplied) {
            Write-Log "The BIOS is already configured correctly. Below is the current values for both variables:"
            Write-Log "`"`$CurrentBIOSSetting.currentSetting`" is:"
            Write-Log
            $CurrentBIOSSetting.CurrentSetting | Out-File -FilePath $LogFile -Append -Force
            Write-Log
            Write-Log "`"`$SettingToBeApplied`" is:"
            Write-Log
            $SettingToBeApplied | Out-File -FilePath $LogFile -Append -Force}
            ((Get-WmiObject lenovo_savebiossettings -ComputerName $ComputerName -Namespace root\wmi).savebiossettings()).return}

if (($SettingsToBeApplied -isnot [string]) -and ($SettingsToBeApplied -isnot [array])) {$SettingsToBeApplied = $SettingsToBeApplied.tostring()}


if (($SettingsToBeApplied -is [string]) -and ($SettingsToBeApplied -match ",")) {Invoke-Command -ScriptBlock $SetBIOSSettingScriptBlock -ArgumentList $SettingsToBeApplied}

if ($SettingsToBeApplied -is [array]) {
    
    foreach ($SettingToBeApplied in $SettingsToBeApplied) {

        #Below is just some more error checking, making sure the input is correct
        if (($SettingToBeApplied -isnot [string]) -or (($SettingToBeApplied -is [string]) -and ($SettingsToBeApplied -notmatch ","))) {
        Write-Log "Each object defined in the array  as the SettingsToBeApplied paramter must be a string containing at least one comma to differentiate a setting name from it's corresponding value."
        Write-Log "The object: $SettingToBeApplied which is found at index#$($SettingsToBeApplied.IndexOf($SettingToBeApplied)) of the `"$SettingsToBeApplied`" fails meet the criteria. "}
        
        #Applying the BIOS Settings below.
        elseif (($SettingToBeApplied -is [string]) -and ($SettingToBeApplied -match ",")) {Invoke-Command -ScriptBlock $SetBIOSSettingScriptBlock -ArgumentList $SettingToBeApplied}}}}
 
Try{
 $settings = "Intel Virtualization Technology,Enabled;[Optional:Disabled,Enabled]"

 $return = Set-LenovoBIOSSettings -SettingsToBeApplied $settings -Verbose -ErrorAction Stop

    If($return -like "Success")
        {Write-Output "Compliant" }
    Else
        { Throw $return }

}catch{ Write-Output "Non-Compliant" }