$ErrorActionPreference = "SilentlyContinue"

##Load the required assemblies
[void] [Reflection.Assembly]::LoadWithPartialName(“System.Windows.Forms”)
[void] [Reflection.Assembly]::LoadWithPartialName("System.Drawing") 
[void] [Reflection.Assembly]::LoadWithPartialName("Microsoft.VisualBasic")


Function NotifyIcon([String]$title,[string]$text)
{
    If(!$title)
        {$title = “Test Title”}
    If(!$text)
        {$text = “Test message”}

    ## Clear Events
    Remove-Event BalloonClicked_event
    Unregister-Event -SourceIdentifier BalloonClicked_event
    Remove-Event BalloonClosed_event
    Unregister-Event -SourceIdentifier BalloonClosed_event
    
    $notification.Dispose()

    ## New Notification Tray Icon
    $notification = New-Object System.Windows.Forms.NotifyIcon
    $notification.Icon = [System.Drawing.SystemIcons]::Question

    $notification.BalloonTipTitle = "Ballon Title"
    $notification.BalloonTipIcon = “Info”
    $notification.BalloonTipText = "Ballon Text"
    $notification.Text = "Note Text"

    $notification.Visible = $True

    ## Register a click event with action to take based on event
 <#       #Balloon message clicked
    register-objectevent $notification BalloonTipClicked BalloonClicked_event `
        -Action {[System.Windows.Forms.MessageBox]::Show(“$text”,”$title”);
            $notification.Visible = $False} | 
                Out-Null
    register-objectevent $notification BalloonTipClosed BalloonClosed_event `
        -Action {[System.Windows.Forms.MessageBox]::Show(“Balloon message closed”,”Information”);
            $notification.Visible = $False } | 
                Out-Null
#>

    $notification.ShowBalloonTip(10000)

    $notification.Click
    $notification.Dispose()

}

Function AddressInfo()
{
    $Addresses = ForEach ($Adapter in (Get-CimInstance Win32_NetworkAdapter -Filter "PhysicalAdapter='True'")){  
                    $Config = Get-WmiObject Win32_NetworkAdapterConfiguration -Filter "Index = '$($Adapter.Index)'"
                        ForEach ($Addr in ($Config.IPAddress)){
                                New-Object PSObject -Property @{
                                    'Adapter' = $Adapter.Name
                                    'IP Address' = $Addr
                                    'MAC Address' = $Config.MacAddress
                                }}}

    $Addresses | where {$_."IP Address" -match  "\d{1,3}(\.\d{1,3}){3}"}
}


Function InfoForm()
{

    Param(
        [string]$title,
        [string]$text
        )

    
    

    $infofrm = New-Object Windows.Forms.form
    $Infofrm.Text = "$title"
    $Infofrm.Width = 550
    $Infofrm.Height = 300
    $Infofrm.AutoScroll = $true
    $Infofrm.ShowInTaskbar = $true
    #$Infofrm.StartPosition = "manual"

    $message = New-Object Windows.Forms.label
    $message.Text = $text
    $message.AutoSize = $true

    $OKbutton = New-Object Windows.Forms.Button
    $OKbutton.Left = 400
    $OKbutton.Top = 200
    $OKbutton.Width = 100
    $OKbutton.Text = “Ok”
    $Okbutton.Add_Click({$InfoFrm.Close()}) 


    $InfoFrm.Controls.Add($message)
    $InfoFrm.Controls.Add($OKbutton)

    
    $Infofrm.TopMost = $true
    $InfoFrm.Add_Shown({$InfoFrm.Activate()})
    $InfoFrm.Visible = $true

    $InfoFrm.ShowDialog()
}