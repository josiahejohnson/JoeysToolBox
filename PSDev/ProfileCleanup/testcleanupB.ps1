function Remove-Profile {
<#
.SYNOPSIS
Deletes local User Profiles from a local or remote computer.
 
.DESCRIPTION
Uses the Delete method of the Win32_UserProfile class.
 
.PARAMETER  ComputerName
The name(s) of the computer to delete profiles from.
Default = Local computer.
 
.PARAMETER  Include
Used to include profiles based on the SID or folder path.
Text entered is used in a wildcard comparison i.e. SID = *expression*    
Include is processed prior to exclude
 
.PARAMETER  Days
Profiles not used for this many days will be deleted.
Default = 30.
 
.PARAMETER  Exclude
Used to exclude profiles based on the SID or folder path.
Text entered is used in a wilcard comparison i.e. SID = *expression*
 
.PARAMETER  $IncludeSystem
Switch that specifies whether the built-in system profiles are included
i.e. NETWORK SERVICE, LOCAL SERVICE, SYSTEM
Default = not included
 
.EXAMPLE
PS C:\> Remove-Profile -Computername "PC1" -Days 10
 
 
.EXAMPLE
PS C:\> "PC1","PC2","PC3" | Remove-Profile -Days 10
 
.EXAMPLE
PS C:\> "PC1","PC2","PC3" | Remove-Profile -Days 10
 
.NOTES
Script Version: 1.0.0
Last update:
2011-10-24 : First Version
 
#>
[CmdletBinding(SupportsShouldProcess=$True,ConfirmImpact="High")]
param(
[Parameter(Position=0, Mandatory=$false,ValueFromPipeLine=$True,ValueFromPipelineByPropertyName=$True)]
[String[]]$Computername=$Env:COMPUTERNAME
,
[Parameter(Position=1, Mandatory=$false,ValueFromPipelineByPropertyName=$True)]
[string]$Include=""
,
[Parameter(Position=2, Mandatory=$false,ValueFromPipelineByPropertyName=$True)]
[int]$Days=30
,
[Parameter(Position=3, Mandatory=$false,ValueFromPipelineByPropertyName=$True)]
[String]$Exclude=""
,
[Parameter(Position=4, Mandatory=$false,ValueFromPipelineByPropertyName=$True)]
[Switch]$IncludeSystem
 
)
BEGIN{
$SystemSIDs = @("S-1-5-20","S-1-5-19","S-1-5-18")
 
}#BEGIN
 
PROCESS{
 
$MaxAge = (Get-Date).AddDays(-$Days)
 
$ComputerName | Foreach-Object{
 
# Setup output
$Property = @{
ComputerName = $_
SID = ""
LocalPath = ""
LastUseTime=""
Loaded=""
Result=""
}
 
if(-not (Test-Connection -ComputerName $_ -Count 1 -Quiet -Verbose:$false)){
Write-Verbose "S_::Ping Failed"
$Property.Item("Result")="Warning::Ping Failed"
return New-Object -TypeName PSObject -Property $Property
}else{
Write-Verbose "$_::Connecting to computer"           
}
 
#region-----WMI query-----
Try{
$UserProfiles = Get-WmiObject -Namespace root\CIMV2 -Class Win32_UserProfile -ComputerName $_ -EnableAllPrivileges -ErrorAction Stop
Write-Verbose "   >> # of cached profiles (Total) = '$(($UserProfiles | Measure-Object).Count)'"
}Catch{
$Property.Item("Result")="Error::Get-WMI Failed, Message $_"
return New-Object -TypeName PSObject -Property $Property
}
#endregion
 
# Exclude system profiles
If(-not $IncludeSystem){
$UserProfiles = $UserProfiles | Where-Object{$SystemSIDs -notcontains $_.SID}
Write-Verbose "   >> # of cached profiles (Non-system) = '$(($UserProfiles | Measure-Object).Count)'"
}
 
#region-----Include filter-----
if($Include){
# Is the exclude a match on sid or path
Switch -regex ($Include){
"S\-[,0-9,\-]*" {
$MatchValue = "SID"
}
Default {
$MatchValue = "LocalPath"
}
}#Switch
$UserProfiles = $UserProfiles | Where-Object{$_.$MatchValue -like "*$Include*"}
Write-Verbose "   >> # of cached profiles in-scope of include = '$(($UserProfiles | Measure-Object).Count)'"
}
 
if(($UserProfiles | Measure-Object).Count -eq 0){
Write-Warning "$_::Specified parameters returned zero results. Try -verbose switch if this is unexpected."
return
}
#endregion
 
Write-Verbose "   >> Profiles older than '$($MaxAge.ToString("u"))' ($Days days) are in-scope for deletion."
 
$UserProfiles | ForEach-Object{
 
$Property.Item("SID") = $_.SID
$Property.Item("LocalPath") = $_.LocalPath
$Property.Item("Loaded") = $_.Loaded
 
if($_.LastUseTime){
$Property.Item("LastUseTime") = (([WMI]'').ConvertToDateTime($_.LastUseTime)).ToString("u")
}else{
 
# Unable to get the date usually means lack of permissions
# Set the date to a day in the future to exclude it
$Property.Item("LastUseTime") = $null
$Property.Item("Result")="Skipped::Unable to get LastUseTime"
New-Object -TypeName PSObject -Property $Property
return
}
 
#Region-----Exclude filter-----
if($Exclude){
# Is the exclude a match on sid or path
Switch -regex ($Exclude){
"S\-[,0-9,\-]*" {
$MatchValue = "SID"
}
Default {
$MatchValue = "LocalPath"
}
}#Switch
 
If($_.$MatchValue -like "*$Exclude*"){
$Property.Item("Result")="Skipped::Excluded"
New-Object -TypeName PSObject -Property $Property
return
}
}#end if
#endregion
 
#region-----Age filter-----
if([DateTime]::Parse($Property.Item("LastUseTime")) -gt $MaxAge){
$Property.Item("Result")="Skipped::Age"
New-Object -TypeName PSObject -Property $Property
return 
}
#endregion
 
if($_.Loaded){
$Property.Item("Result")="Skipped::In-use"
New-Object -TypeName PSObject -Property $Property                   
}Else{
if($PSCmdLet.ShouldProcess($Property["Computername"],"Delete profile $($_.LocalPath), last used $($Property.Item('LastUseTime'))")){
# PROFILE DELETE
Try{
$_.Delete() | Out-Null
$Property.Item("Result")="Success::Deleted Profile"
}Catch{
$Property.Item("Result")="Error::Delete Failed, Message $_"
 
# Most common issue is a file in-use
$ProfilePath = "\\$($Property['Computername'])\$($Property["Localpath"] -Replace 'C:\\','C$\')"
$Files = @(Dir -Recurse -Force -Path $ProfilePath -EA 0 | ?{-not $_.PSIsContainer})
if($Files.Count -ge 1){
$Property.Item("Result")+=", $($Files.Count) files remain in profile folder"
}#Endif Files
}#catch
 
New-Object -TypeName PSObject -Property $Property
 
}else{
$Property.Item("Result")="Skipped::By Operator (-WhatIf or -Confirm)"
New-Object -TypeName PSObject -Property $Property
}#whatif
}#EndIf Loaded
 
}#Foreach UserProfile
 
}#Foreach Computer
 
}#Process
 
END{}
 
}#EndFunction