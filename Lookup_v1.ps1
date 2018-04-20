$ErrorActionPreference = "SilentlyContinue"


Function ClearAndClose()
 {
    (gwmi win32_operatingsystem).win32shutdown(0)
    $Timer.Stop();
    $ie.Quit();
    $objform.Close();
    $objform.Dispose();
    $Timer.Dispose();
    $message.Dispose();
    $LogOff.Dispose();
    $StartOver.Dispose();
    $Script:CountDown=600
 } 

 Function YouWillComply()
 {
         If(($Script:CountDown -eq 300) -and !$shown )
            { WarningMessage }
         ElseIf ($Script:CountDown -lt 0)
            { ClearAndClose }
         If($ie.ReadyState -eq $null){ ClearAndClose }
         If(Get-Process -Name "firefox" -ErrorAction SilentlyContinue){Stop-Process -Name "Firefox"}
         If(Get-Process -Name "chrome" -ErrorAction SilentlyContinue){Stop-Process -Name "chrome"}
 }

 Function WarningMessage()
 {
    [Windows.Forms.MessageBox]::Show("You only have 5 minutes remaining before this system will log off!","Time Remaining",[Windows.Forms.MessageBoxButtons]::OK,[Windows.Forms.MessageBoxIcon]::Warning) | Out-Null
    $shown = $true
 }

 ## Setup env
[void] [Reflection.Assembly]::LoadWithPartialName("System.Drawing") 
[void] [Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
[void] [Reflection.Assembly]::LoadWithPartialName("Microsoft.VisualBasic")
[void] [Windows.Forms.Application]::EnableVisualStyles()

#$screen = [Windows.Forms.Screen]::PrimaryScreen.Bounds
$screen = gwmi "Win32_VideoController" | 
    Select @{N='width';E={$_.CurrentHorizontalResolution}}, @{N='height';E={$_.CurrentVerticalResolution}} -Unique

$url = "https://www.grcc.edu/pwd"


## Build IE Window
$ie = new-object -ComObject "InternetExplorer.Application"
    $ie.ToolBar = $false
    $ie.StatusBar = $false
    $ie.menubar = $false
    $ie.Resizable = $false
    $ie.AddressBar = $false
    $ie.FullScreen = $true
    #$ie.Width = $screen.width
    #$ie.Height = $screen.height - 150
    #$ie.Top = 0
    #$ie.Left= 0
$ie.Visible = $true
$ie.Navigate($url)

While ($ie.busy){ Start-Sleep -Seconds 1 }

## Build Form
$objform = New-Object Windows.Forms.form
    $objform.Text = "Log Off Button"
    $objform.Width = $screen.Width
    $objform.Height = 150
    $objform.AutoScroll = $true
    $objform.ControlBox = $false
    $objForm.ShowInTaskbar = $False
    $objform.StartPosition = "manual"
    $objform.top = $screen.Height - 149
    $objform.Left = 0

## Set fonts
$mFont = New-Object Drawing.Font("Lucida Console",14,[System.Drawing.FontStyle]::Italic)
$bFont = New-Object Drawing.Font("Lucida Console",14,[System.Drawing.FontStyle]::Bold)

## Build Message 
$message = New-Object Windows.Forms.Label
    $message.Text = "Your system will automatically log off in 10 minutes. `nPlease set your password and log off!"
    $message.TextAlign = "TopCenter"
    $message.Width = 800
    $message.Height = 50
    #$message.AutoSize
    #$message.Location = New-Object Drawing.Size(($objform.Width / 2 - $message.Width / 2),10)
    $message.Top = 10
    $message.Left = ($objform.Width / 2 - $message.Width / 2)
    $Message.Font = $mFont

## LogOff Button
$LogOff = New-Object Windows.forms.button
    $LogOff.Text = "&Log Off"
    $LogOff.Font = $bFont
    $Logoff.FlatStyle = "Standard"
    $LogOff.Width = 150
    $LogOff.Height = 35
    #$LogOff.AutoSize = $true
    #$LogOff.Location = New-Object Drawing.Size(($objform.Width / 2 + $LogOff.Width ),60)
    $LogOff.Top = 60
    $LogOff.left = ($objform.Width / 2) + 10
    $LogOff.add_click({ClearAndClose})

## Home Button
$StartOver = New-Object Windows.forms.button
    $StartOver.Text = "&Start Over"
    $StartOver.Font = $bFont
    $StartOver.FlatStyle = "Standard"
    $StartOver.Width = 200
    $StartOver.Height = 35
    #$StartOver.AutoSize = $true
    #$StartOver.Location = New-Object Drawing.Size(($objform.Width / 2 - 5 - $StartOver.width ),60)
    $StartOver.Top = 60
    $StartOver.Left = ($objform.Width / 2) - ($StartOver.Width + 10)
    $StartOver.add_click({$ie.Navigate($url)})


##Add Buttons to Form
$objform.controls.Add($message)
$objform.Controls.Add($LogOff)
$objform.Controls.Add($StartOver)

## Make Visable
$objform.TopMost = $true
$objForm.Add_Shown({$objForm.Activate()})
$objform.add_FormClosing({ClearAndClose})

## Timer
$Timer = New-Object Windows.Forms.Timer
    $Timer.Interval = 1000
    $Script:CountDown = 600
    $Timer.Add_Tick({ --$Script:CountDown ; YouWillComply})

## Launch Form
$timer.Start()
[void]$objform.ShowDialog()


