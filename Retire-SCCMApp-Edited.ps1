function Update-Log ($text) {
    $LogTextBox.AppendText("$text")
    $LogTextBox.Update()
    $LogTextBox.ScrollToCaret()
}

Function Move-Repository($Path,$appName){
       ## Rights to Folders
        $SCCMuser = ##"user"##
        $passWord = ##"encryptedpassword"##
        $creds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $SCCMuser,( $passWord | ConvertTo-SecureString )
        Push-location "$env:windir"
        Try
            {
                If(!(Test-path $path) )
                    { 
                        New-item -Path "\\server\path\Tools\_Retired" -Name "$appName" -ItemType Directory -Credential $creds -Force -ea Stop 
                    }
                Move-Item -Path "$Path" -Destination "\\server\path\Tools\_Retired\$appName" -Force -Credential $creds -ea Stop
                Write-Output "Moved to: '\\server\path\Tools\_Retired\$appName'`n"
            }
        Catch {Write-Output "Failed to move repository to: '\\server\path\Tools\_Retired'`n"}
        Pop-Location
        
}


function Retire-CMApplication {

    [CmdletBinding()]
    param (
        $SiteCode = "",
        $SiteServer = "",
        $retiredFolder = "_Retired",
        $RetiringApps
        
    )

## Connect to Server
Update-Log "`n................`n"
Update-Log "Importing SCCM powershell module..."
Update-Log "`n................`n"

If((Get-Location).path.Substring(0,3) -notmatch "$($SiteCode)")
    {
        Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1" # Import the ConfigurationManager.psd1 module 
        if ((get-psdrive $SiteCode -erroraction SilentlyContinue | measure).Count -ne 1)
	        {
		        Try{new-psdrive -Name $SiteCode -PSProvider "AdminUI.PS.Provider\CMSite" -Root $SiteServer -ErrorAction Stop}
                Catch{ Update-Log "$($error[0].Exception.Message)" }
	        }
        Set-Location "$($SiteCode):" # Set the current location to be the site code.
    }

## Get distribution Points
    $DPs = Get-CMDistributionPoint
    $DPGs = Get-CMDistributionPointGroup


If(!$RetiringApps)
    {
        $RetiringApps = @(Get-CMApplication -Fast | 
                            Select LocalizedDisplayName,Manufacturer,SoftwareVersion,NumberOfDevicesWithApp,HasContent,IsExpired,ModelName |
                                Where { !$_.LocalizedDisplayName.startswith("Retired-") } |
                                    Sort LocalizedDisplayName | Out-GridView -Title "Select Apps to Retire" -OutputMode Multiple )
    }

If($RetiringApps){


Update-Log "`n................`n"
Update-Log "Start"
Update-Log "`n................`n"


## Process Each App
Foreach($app in $RetiringApps)
    {
    ## Get all info on choosen app
        $appName = $app.LocalizedDisplayName
        $RetiringApp = Get-CMApplication -ModelName "$($app.modelName)"

    ## Start App Record
        Update-Log "`n................`n"
        Update-Log "Retiring: $appName.`n"
        
    ## Activate Incorrectly Retired Apps
        If ($RetiringApp.IsExpired) {
                Resume-CMApplication -InputObject $RetiringApp -ErrorAction SilentlyContinue | Out-Null
                Update-Log "Setting $appName to Active so that changes can be made.`n"
            }

    ## removing all deployments from App
        Get-CMDeployment -SoftwareName "$($RetiringApp.LocalizedDisplayName)" | Remove-CMDeployment -Force -ErrorAction SilentlyContinue | Out-Null
        Update-Log "Removing Deployments from: $appName.`n"

    ## Remove Content from Distribution Point
        If($RetiringApp.HasContent -eq $true)
            {
                Update-Log "Removing content from all distribution points.`n"
                foreach ($DP in $DPs)
                    { 
                        try{ Remove-CMContentDistribution -Application $RetiringApp -DistributionPointName ($DP).NetworkOSPath -Force -EA SilentlyContinue | Out-Null }
                        catch{ <#Update-Log "$($error[0].Exception.Message)"#> } 
                    }
                Update-Log "Removing content from all distribution point groups.`n"
                foreach ($DPG in $DPGs)
                    {
                        try{Remove-CMContentDistribution -Application $RetiringApp -DistributionPointGroupName ($DPG).Name -Force -EA SilentlyContinue | Out-Null }
                        catch{ <#Update-Log "$($error[0].Exception.Message)" #> }
                    }
            }
        Else
            {Update-Log "No Content Found for: $appName.`n"}

    ## Remove Extra Revisions


    ## Move App to Retired Folder
        Move-CMObject -FolderPath "$($SiteCode):\Application\$($retiredFolder)" -InputObject $RetiringApp -ErrorAction SilentlyContinue | Out-Null
        Update-Log "Moving $appName to $retiredFolder folder.`n"

    ## Rename Application to Retired-
        Set-CMApplication -Name "$($RetiringApp.LocalizedDisplayName)" -NewName "Retired-$($RetiringApp.LocalizedDisplayName)" -ErrorAction SilentlyContinue | Out-Null
        Update-Log "Renaming $appName to 'Retired-$appname'.`n"

        ## Retire the App
        Suspend-CMApplication -InputObject $RetiringApp -ea SilentlyContinue | out-Null
        Update-Log "Setting Status of $appName to Retired.`n"
    
    ## End App Record
        Update-Log "Retired: $appName."
        Update-Log "`n................`n"

    # return source files location
        $xml = [xml]$RetiringApp.SDMPackageXML
        $loc = $xml.AppMgmtDigest.DeploymentType.Installer.Contents.Content.Location
        Update-Log "`nSource files are located at:`n"
        Foreach($l in $loc)
            {
                Update-log "'$l'`n"
                $MoveReturn = Move-Repository -Path "$l" -appName "$appname"
                Update-log "$MoveReturn`n"
                <#
                New-item -Path "\\server\path\Tools\_Retired" -Name "$appName" -ItemType Directory -Force -Credential $Creds 
                Move-Item -Path "$l" -Destination "\\server\path\Tools\_Retired\$appName" -Force -Credential $Creds 
                Update-log "Moved to:`n'\\server\path\Tools\_Retired\$appName'`n"
                #>
            }
        Update-Log "`n................`n"

    }
}
Else
    {
        Update-Log "`n................`n"
        Update-Log "No Applications Selected"
        Update-Log "`n................`n"
    }

Update-Log "`n................`n"
Update-Log "Complete"
Update-Log "`n................`n`n`n`n`n`n`n`n`n"
}


# user form
function Create-UtilityForm {
    
    [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 
    [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")

    $objForm = New-Object System.Windows.Forms.Form 
    $objForm.Text = "SCCM App Retire"
    $objForm.Size = New-Object System.Drawing.Size(500, 600) 
    $objForm.StartPosition = "CenterScreen"

    # Creates output log
    $LogTextBox = New-Object System.Windows.Forms.RichTextBox
    $LogTextBox.Location = New-Object System.Drawing.Size(12, 50) 
    $LogTextBox.Size = New-Object System.Drawing.Size(460, 500)
    $LogTextBox.ReadOnly = 'True'
    $LogTextBox.BackColor = 'Black'
    $LogTextBox.ForeColor = 'White'
    $LogTextBox.Font = 'Consolas'
    $objForm.Controls.Add($LogTextBox)

    # app retire button
    $AppRetireButton = New-Object System.Windows.Forms.Button
    $AppRetireButton.Location = New-Object System.Drawing.Size(12, 14)
    $AppRetireButton.Size = New-Object System.Drawing.Size(75, 22)
    $AppRetireButton.Text = "Retire"
    $AppRetireButton.Add_Click(
        { Script:Retire-CMApplication  })
    $objForm.Controls.Add($AppRetireButton)
    
    # clear log button
    $clearButton = New-Object System.Windows.Forms.Button
    $clearButton.Location = New-Object System.Drawing.Size(395, 14)
    $clearButton.Size = New-Object System.Drawing.Size(75, 22)
    $clearButton.Text = "Clear Log"
    $clearButton.Add_Click(
        { $LogTextBox.Clear() })
    $objForm.Controls.Add($clearButton)

    $objForm.Add_Shown({$objForm.Activate()})
    [void] $objForm.ShowDialog()
}


    Create-UtilityForm
