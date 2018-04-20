Function Get-SystemInfoPage(){ 

[cmdletbinding()]
Param(
    [switch]$full,
    [switch]$networkSave,
    [switch]$NoUI,
    #[ValidateNotNull()]
    [System.Management.Automation.PSCredential]
    [System.Management.Automation.Credential()]
    [System.Management.Automation.PSCredential]$Credential
)

If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
    [Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    Write-Warning "You do not have Administrator rights to run this script!`nPlease re-run this script as an Administrator!"
    Break
}


#region HTML Output Formatting
$style = "
<style>
BODY{background-color:white ;}
TABLE{border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;}
TH{border-width: 1px;padding: 3px;border-style: solid;border-color: black;background-color:LightSteelBlue}
TD{border-width: 1px;padding: 3px;border-style: solid;border-color: black}
tr:nth-child(odd) { background-color:white;}
tr:nth-child(even) { background-color:MintCream ;}
</style>
"
#endregion


### Globals ###
$cn = $env:COMPUTERNAME
$currentuser = "$env:USERDOMAIN\$env:USERNAME"
$foldername = (get-date -Format ddMMMyyyy).ToString()
$netPath = "\\cold.grcc.edu\sccm\SharedApps\Inventory\"

### File Location ###
If($networkSave)
    {
        $filepath = "$netpath\$foldername"
        If(!(Test-Path -Path $filepath)){new-item -Path "$netPath" -Name "$foldername" -ItemType Directory -Force | out-null }
    }
Else
    {
        $filepath = "$env:ProgramFiles\$FolderName"
        If(!(Test-Path -Path $filepath)){new-item -Path "$env:ProgramFiles" -Name "$FolderName" -ItemType Directory -Force | out-null }
    }

#region WMI queries
[wmi]$enclosure = gwmi win32_systemenclosure -ComputerName $cn
[wmi]$system = gwmi win32_computersystem -ComputerName $cn
[wmi]$OS = gwmi win32_OperatingSystem -ComputerName $cn

$Addresses = ForEach ($Adapter in (Get-CimInstance Win32_NetworkAdapter -Filter "PhysicalAdapter='True'")){  
                    $Config = Get-WmiObject Win32_NetworkAdapterConfiguration -Filter "Index = '$($Adapter.Index)'"
                        ForEach ($Addr in ($Config.IPAddress)){
                                New-Object PSObject -Property @{
                                    'Adapter' = $Adapter.Name
                                    'IP Address' = $Addr
                                    'MAC Address' = $Config.MacAddress
                                }}}

switch($enclosure.ChassisTypes){ 
        1 {$chassis = "Other"} 
        3 {$chassis = "Desktop"} 
        6 {$chassis = "Mini Tower"} 
        7 {$chassis = "Desktop"}
        8 {$chassis = "Laptop"}
        9 {$chassis = "Laptop "}
        10 {$chassis = "Laptop"}
        13 {$chassis = "All-in-One"}
        default {$chassis = "Unknown"}
    }
#endregion


##title
ConvertTo-Html -Title "System Information for $cn" -Body "<h3> System Information for $cn </h3>" | Out-File -Force  "$filepath\$cn.html" 




#region System Info
$table1 = New-Object -TypeName PSObject
$table1 | Add-Member NoteProperty -Name 'Computer Name' -value $system.name
$table1 | Add-Member NoteProperty -Name 'Current User' -value $system.UserName
$table1 | Add-Member NoteProperty -Name 'Asset Tag' -value $enclosure.SMBIOSAssetTag
$table1 | Add-Member NoteProperty -Name 'Serial Number' -value $enclosure.SerialNumber
If($enclosure.SMBIOSassettag.count -eq 6){$table1 | Add-Member NoteProperty -Name 'Asset Tag' -value $enclosure.SMBIOSAssettag}
$table1 | Add-Member NoteProperty -Name 'Manufacturer' -value $system.Manufacturer
$table1 | Add-Member NoteProperty -Name 'Model Number' -value $system.Model
$table1 | Add-Member NoteProperty -Name 'System Type' -Value $chassis

$table1 | ConvertTo-html -As Table -Head $style | Out-File -Append "$filepath\$cn.html"
#endregion



#region Connection info
$Addresses | Select 'IP Address',Adapter,'Mac Address' | where {$_.'IP Address' -match "\d{1,3}(\.\d{1,3}){3}"} | 
    ConvertTo-html -As Table -Head $style -Body "<h3> Connection Info </h3>" | 
        Out-File -Append "$filepath\$cn.html"
#endregion




#region OS Info
$table2 = New-Object -TypeName PSObject
$table2 | Add-Member NoteProperty -Name 'Operating System' -value $os.Caption
$table2 | Add-Member NoteProperty -Name 'OS Version' -value $os.Version
$table2 | Add-Member NoteProperty -Name 'Architecture' -value $os.OSArchitecture

$table2 | ConvertTo-html -As Table -Head $style -Body "<h3> Operating System </h3>" | Out-File -Append "$filepath\$cn.html"
#endregion




#region Endpoint Info
$table3 = New-Object -TypeName PSObject
$table3 | Add-Member NoteProperty -Name "Client Version" -Value (Get-ItemProperty -Path "hklm:\Software\Microsoft\SMS\Mobile Client")."ProductVersion"
$table3 | Add-Member NoteProperty -Name "Last Eval Time" -Value (get-date (Get-ItemProperty -Path "hklm:\Software\Microsoft\CCM\CCMEval")."LastEvalTime" -Format "MM-dd-yyyy @ hh:mm")

If($os.Version.Substring(0,2) -eq 10)
    {
        Try{ Import-Module $env:SystemRoot\System32\WindowsPowerShell\v1.0\Modules\Defender\Defender.psd1 -ErrorAction Stop | Out-Null }
        Catch{ Import-Module "$env:SystemRoot\sysnative\WindowsPowerShell\v1.0\Modules\Defender\Defender.psd1" -ErrorAction Continue | Out-Null }
        $table3 | Add-Member NoteProperty -Name "Signature Version" -value (Get-MpComputerStatus).AntivirusSignatureVersion
        $table3 | Add-Member NoteProperty -Name "Signature Last Updated" -value (get-date (Get-MpComputerStatus).AntivirusSignatureLastUpdated -Format "MM-dd-yyyy @ hh:mm")
    }
If($os.Version.Substring(0,2) -ne 10)
    {
        Import-Module “$env:ProgramFiles\Microsoft Security Client\MpProvider” | Out-Null
        $table3 | Add-Member NoteProperty -Name "Signature Version" -value (Get-MprotComputerStatus).AntivirusSignatureVersion
        $table3 | Add-Member NoteProperty -Name "Signature Last Updated" -value (get-date (Get-MprotComputerStatus).AntivirusSignatureLastUpdated -Format "MM-dd-yyyy @ hh:mm")
    }


$table3 |  ConvertTo-HTML -as Table -Body "<h3> Endpoint Information </h3>" | Out-File -Append "$filepath\$cn.html"
#endregion




#region Disk Info
Get-WMIObject -ComputerName $cn Win32_LogicalDisk | 
    Where-Object{$_.DriveType -eq 3} |
        Select-Object Name,VolumeName,  @{n='Size (GB)';e={"{0:n2}" -f ($_.size/1gb)}}, @{n='FreeSpace (GB)';e={"{0:n2}" -f ($_.freespace/1gb)}}, @{n='Percent Free';e={"{0:n2}" -f ($_.freespace/$_.size*100)}} | 
            ConvertTo-HTML -as Table -Body "<h3> Disk Info </h3>" | Out-File -Append "$filepath\$cn.html"
#endregion




#region Installed Software

If($full)
{
## Installed Software
$regapps = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* |  
    Select-Object @{n="Name";e={$_.DisplayName}},@{n='Version';e={$_.DisplayVersion}},Publisher, @{n='Install Date';e={ $_.Installdate } }
$wmiApps = Get-CimInstance -ClassName Win32_Product | Select Name,Version,@{n="Publisher";e={$_.Vendor}},@{n='Install Date';e={ $_.Installdate } }
$apps = $regapps + $wmiApps | sort -Property Name -Unique | where {$_.Name -ne $null}

$apps |  ConvertTo-HTML -as Table -Body "<h3> Installed Software </h3>" | Out-File -Append "$filepath\$cn.html"
}
#endregion




##footer
ConvertTo-html -body "<br/>The Report is generated On  $(get-date) by $($system.UserName) on computer $($cn)" | Out-File -Append "$filepath\$cn.html" 

##execute
If(!$NoUI)
    { invoke-item "$filepath\$cn.html" }
Else
    {
        Write-Host "$filepath\$cn.html"
        exit 0
    }

}
