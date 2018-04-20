<#	
	.NOTES
	===========================================================================
	 Created on:   2/24/2015 9:24 AM
	 Created by:   johnsonj
	 Organization: GRCC
	 Filename:     SCCM-Functions
	 Version:      1.1
	===========================================================================
	.DESCRIPTION
		Refresh SCCM Policies. Requires administrators rights
#>

$ErrorActionPreference = 'Continue'
#Requires -Version 2

Write-Verbose "Importing SCCM-Refresh module"
Function SCCM-Refresh
{
	<#
	.SYNOPSIS
	Used to Refresh SCCM and Group Policies
	.DESCRIPTION
	Used to Refresh SCCM and Group Policies
	.PARAMETER Policy
	Select the Policy to refresh. Defaults to All
	.PARAMETER GUI
	If specified the UI is disabled and output is displayed in command prompt.
	.EXAMPLE
	SCCM-Refresh -policy Machine,Inventory -UI -Verbose
	#>
	
	[CmdLetBinding()]
	param (
		[Parameter(ValueFromPipeline = $true, HelpMessage = "Enter one or more ComputerName separated by commas(,)")]
		[Alias("CN", "Comp", "Computer")]
		[String[]]$Computername = $env:COMPUTERNAME,
		
		[Parameter(ValueFromPipeLine = $true, HelpMessage = "Enter one or more Policy separated by commas(,)")]
		[Alias("pol", "po")]
		[ValidateSet("ALL", "GPO", "Machine", "Inventory", "State", "Updates", "Clean", "DDR")]
		[String[]]$policy,
		
		[Parameter(ValueFromPipeLine = $True, HelpMessage = "Enter -NoUI to run in command line mode")]
		[Alias("UI")]
		[Switch]$GUI
		
	)
	
	#Set Policy if not provided
	If (!$policy) { $policy = "All" }
	
	#GPUpdate /force
	If (($policy -ieq "ALL") -or ($policy -ieq "gpo"))
	{
		[Array]$results += Refresh-GPO
	}
	
	#SCCM Machine Policy Refresh
	If (($policy -ieq "ALL") -or ($policy -ine "GPO"))
	{
		[Array]$results += ( Refresh-SCCMPolicy -policy $policy )
	}
	
	#Build and Show Form
	If ($GUI)
	{
		# Load assembly and Build Form
		[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")
		[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
	
		#create diaglog box
		$objForm = New-Object System.Windows.Forms.Form
		$objForm.Text = "Policy Refresh"
		$objForm.Size = New-Object System.Drawing.Size(280, 280)
		$objForm.MinimizeBox = $false
		$objForm.MaximizeBox = $false
		$objForm.WindowState = 'Normal'
		$objForm.ShowInTaskbar = $false
		$objForm.StartPosition = "CenterScreen"
		$objForm.Topmost = $True
		$objForm.KeyPreview = $True
		$objForm.Add_KeyDown({
			if ($_.KeyCode -ieq "Enter")
			{ $objForm.Close() }
		})
		$objForm.Add_KeyDown({
			if ($_.KeyCode -ieq "Escape")
			{ $objForm.Close() }
		})

		#create a OK button
		$OKButton = New-Object System.Windows.Forms.Button
		$OKButton.Location = New-Object System.Drawing.Size(100, 210)
		$OKButton.Size = New-Object System.Drawing.Size(75, 23)
		$OKButton.TabIndex = 0
		$OKButton.Text = "&OK"
		$OKButton.Add_Click({ $objForm.Close() })

		#Create Label
		$objLabel = New-Object System.Windows.Forms.Label
		$objLabel.Location = New-Object System.Drawing.Size(20, 10)
		$objLabel.AutoSize = $True
		$objLabel.Text = "Policies Refreshed on $Computername"

		#Create TextBox
		$objtextBox = New-Object system.Windows.Forms.RichTextBox
		$objtextBox.Location = New-Object System.Drawing.Size(5, 40)
		$objtextBox.Size = New-Object System.Drawing.Size(250, 220)
		$objtextBox.Height = 160

		#Add Data to TextBox
		foreach ($result in $results)
		{
			$start = $objtextBox.Text.Length
			$objtextbox.AppendText("$result`n")
			$end = $objtextBox.Text.Length
			$length = $end - $start
			$objtextbox.Select($start, $length)
			#Set Color of text
			If ($Result -icontains "Failed") { $color = "DarkRed" }
			Else { $color = "black" }
			$objtextbox.SelectionColor = $color
		}

		#Build Form
		$objForm.Controls.Add($OKButton)
		$objForm.Controls.Add($objLabel)
		$objForm.Controls.Add($objtextBox)

		#Load Form
		$objForm.Add_Shown({ $objForm.Activate() })
		[void] $objForm.ShowDialog()

		#Keep proccess open until GPupdate is done
		IF (Get-Job -Name 'GPUpdate' -ea 'SilentlyContinue')
		{
			Wait-job -Name 'GPUpdate' | Out-Null
			Remove-Job -Name 'GPUpdate' | Out-Null
			Write-Host "Group Policy Update Complete" -ForegroundColor 'DarkCyan'
		}
	}

	#Write to concole if NoUI is specified
	If (!$GUI)
	{
		Foreach ($result in $results)
		{
			If ($result -icontains "Failed") { Write-Host $result -ForegroundColor 'DarkRed' }
			Else { Write-Host $result }
		}
		IF (Get-Job -Name 'GPUpdate' -ea 'SilentlyContinue')
		{
			Wait-Job -Name 'GPUpdate' | Out-Null
			Remove-Job -Name 'GPUpdate' | Out-Null
			Write-Host "Group Policy Update Complete" -ForegroundColor 'DarkCyan'
		}
	}
}

Write-Verbose "Importing Refresh-GPO Module"
Function Refresh-GPO
{
	[CmdLetBinding()]
	param (
		[Parameter(ValueFromPipeLine = $True)]
		[String]$Computername = $env:COMPUTERNAME
	)
	#Check Domain Membership
	$CS = GWMI Win32_ComputerSystem -ComputerName $Computername -ea 'SilentlyContinue'
	If ($CS.partofdomain)
	{
		$Domain = $CS.domain
		Write-Verbose "System is a member of $Domain"
		Try
		{
			$null = [System.DirectoryServices.ActiveDirectory.Domain]::GetComputerDomain()
			$isDomain = $true
		}
		catch { $isDomain = $false }
		If ($isDomain)
		{
			Write-Verbose "Connection to $Domain confirmed, continuing with GPUpdate"
			#Start GPupdate Proccess
			$gpo = (Start-Job -ScriptBlock { gpupdate /force /wait:0 } -Name 'GPUpdate' -ErrorAction 'Continue')
			If ($gpo) { Write-Output "Group Policy Update Started" }
			Else { Write-Output "Failed to Update Group Policy!" }
		}
		Else
		{
			Write-Verbose "Could not connect to the Domain Skipping GPUpdate"
			Write-Output "Failed to connect to $Domain"
		}
	}
	Else
	{
		Write-Verbose "System is not a member of a Domain Skipping GPUpdate"
		Write-Output "Failed To Determine Domain"
	}
}

Write-Verbose "Importing Refresh-SCCMPolicy Module"
Function Refresh-SCCMPolicy
{
	[CmdLetBinding()]
	param (
		[Parameter(ValueFromPipeLine = $True)]
		[String]$Computername = $env:COMPUTERNAME,
		[String]$siteServ = "SCCM.AD.GRCC.EDU",
		[Parameter(ValueFromPipeLine = $True, ValueFromPipelineByPropertyName = $true)]
		[ValidateSet("ALL", "Machine", "Inventory", "State", "Updates", "Clean", "DDR","GPO")]
		[Alias("POL", "PO")]
		[String[]]$policy
	)

	If ($policy -ieq "GPO") { Return }
	If ($policy -ieq "ALL") { $policy = "Clean", "Machine", "State", "DDR", "Inventory", "Updates" }
	#Check SCCM Membership
	$SMSCli = [wmiclass] "\\$computername\root\ccm:SMS_Client"
	IF ($SMSCli)
	{
		Write-Verbose "Successfully Loaded SCCM Client Controls"
		Try
		{
			$SiteCon = (Test-Connection $siteServ -Count 1 -ea 'SilentlyContinue')
		}
		Catch { $SiteCon = $false }
		If ($SiteCon)
		{
			Write-verbose "Connection to $siteServ confirmed, continuing with policy Refresh"
			ForEach ($p in $policy)
			{
				#Set Policy Script Blocks
				Switch ($p)
				{
					Machine {
						$ExecPolicy = {
							Try
							{
								Write-Verbose "Requesting Updated Machine Policies"
								$SMSCli.RequestMachinePolicy() | Out-Null
								$SMSCli.EvaluateMachinePolicy() | Out-null
							}
							Catch
							{
								Write-Error $Error
								Write-Output "Unable to Start $p Policy Refresh"
							}
						}
					}
					Inventory {
						$ExecPolicy = {
							Try
							{
								Write-Verbose "Requesting Hardware Inventory Update"
								$SMSCli.TriggerSchedule('{00000000-0000-0000-0000-000000000001}') | Out-null
								Write-Verbose "Requesting Software Inventory Update"
								$SMSCli.TriggerSchedule('{00000000-0000-0000-0000-000000000002}') | Out-null
							}
							Catch
							{
								Write-Error $Error
								Write-Output "Unable to Start $p Policy Refresh"
							}
						}
					}
					State {
						$ExecPolicy = {
							Try
							{
								Write-Verbose "State Message Update Started"
								$SMSCli.TriggerSchedule('{00000000-0000-0000-0000-000000000111}') | Out-null
							}
							Catch
							{
								Write-Error $Error
								Write-Output "Unable to Start $p Policy Refresh"
							}
						}
					}
					Updates {
						$ExecPolicy = {
							Try
							{
								Write-Verbose "Software Update Scan Started"
								$SMSCli.TriggerSchedule('{00000000-0000-0000-0000-000000000113}') | Out-null
								Write-Verbose "Software Update Deployment Started"
								$SMSCli.TriggerSchedule('{00000000-0000-0000-0000-000000000108}') | Out-null
							}
							Catch
							{
								Write-Error $Error
								Write-Output "Unable to Start $p Policy Refresh"
							}
						}
					}
					Clean {
						$ExecPolicy = {
							Try
							{
								Write-Verbose "Reseting Machine Policies"
								$SMSCli.ResetPolicy() | Out-Null
								Write-Verbose "Cleaning Up Old Policies"
								$SMSCli.TriggerSchedule('{00000000-0000-0000-0000-000000000040}') | Out-null
								Write-Verbose "Cleaning Up Message Cache"
								$SMSCli.TriggerSchedule('{00000000-0000-0000-0000-000000000112}') | Out-null
							}
							Catch
							{
								Write-Error $Error
								Write-Output "Unable to Start $p Policy Refresh"
							}
						}
					}
					DDR {
						$ExecPolicy = {
							Try
							{
								Write-Verbose "Discovery Data Refresh Started"
								$SMSCli.TriggerSchedule('{00000000-0000-0000-0000-000000000003}') | Out-null
							}
							Catch
							{
								Write-Error $Error
								Write-Output "Unable to Start $p Policy Refresh"
							}
						}
					}
					All {
						$ExecPolicy = {
							Try
							{
								$SMSCli.RequestMachinePolicy() | Out-Null
								$SMSCli.EvaluateMachinePolicy() | Out-null
							}
							Catch
							{
								Write-Error $Error
								Write-Output "Unable to Start $p Policy Refresh"
							}
						}
					}
					default
					{
						$ExecPolicy = {
							Try
							{
								$SMSCli.RequestMachinePolicy() | Out-Null
								$SMSCli.EvaluateMachinePolicy() | Out-null
							}
							Catch
							{
								Write-Error $Error
								Write-Output "Unable to Start $p Policy Refresh"
							}
						}
					}
				}
				$Refresh = (Start-Job -ScriptBlock $ExecPolicy -Name $p)
				If ($Refresh) { Write-Output "$p Policy Refresh Started" }
				Else
				{
					Write-Output "Failed to Refresh $p Policy!"
				}
			}
		}
		Else
		{
			Write-Verbose "Could not connect to $siteServ Skipping Policy Updates"
			Write-Output "Could not connect to $siteServ"
		}
	}
	Else
	{
		Write-Verbose "Could Not Load SCCM Client Controls"
		Write-Output "Could Not Load Client Controls"
	}
}

#SCCM-Refresh