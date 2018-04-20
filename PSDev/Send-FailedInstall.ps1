$ErrorActionPreference = "Continue"

Function Send-Email {
[CmdLetBinding()]

    Param(
        [String]$SMTPserv = "SMTP.GRCC.EDU",
        [Parameter(ValueFromPipeLine = $True)]
        [String]$smtpFrom,
        [Parameter(ValueFromPipeLine = $True)]
        [String]$Subject,
        [Parameter(ValueFromPipeLine = $True)]
        [String]$smtpTo,
        [Parameter(ValueFromPipeLine = $True)]
        [String]$smtpCC,
        [Parameter(ValueFromPipeLine = $True)]
        [String]$smtpBCC,
        [Parameter(ValueFromPipeLine = $True)]
        [String]$message,
        [Parameter(ValueFromPipeLine = $True)]
        $file
    )

        Process{
            # Create Message
        $msg = new-object System.Net.Mail.MailMessage 
        $msg.From = $smtpFrom 
        $msg.To.Add($smtpTo) 
        $msg.CC.Add($smtpCC) 
        #$msg.Bcc.Add($smtpbcc) 
        $msg.IsBodyHtml = $false 
        $msg.Subject = $Subject
        $MSG.Body = $message

            # Create Attachment
        $att = new-object Net.Mail.Attachment($file)
        $msg.Attachments.Add($att)

            # Create Message
        $smtp = New-Object Net.Mail.SMTPClient ($SMTPserv)
        $SMTP.Send($msg)
        
        $att.Dispose() 
        }
    }

Try{
$CompName = $env:COMPUTERNAME

$comp = gwmi win32_computersystem | Select *
    $make = $comp.Manufacturer
    $model = $comp.Model

$assettag = (gwmi win32_systemenclosure).SMBIOSAssetTag

$SN = (gwmi win32_systemenclosure).SerialNumber

$type = Switch ( (gwmi win32_systemenclosure).chassistypes )
            {
                1 { "Other" }
                2 { "Unknown" }
                3 { "Desktop" }
                4 { "Desktop" }
                5 { "Desktop" }
                6 { "Desktop" }
                7 { "Desktop" }
                8 { "Portable" }
                9 { "Laptop" }
                10 { "Laptop" }
                13 { "AllinOne" }
                14 { "Laptop" }
                default { "Unknown" }
            }

$OS = (gwmi win32_operatingsystem).Caption + "(" + (gwmi win32_operatingsystem).OSArchitecture + ")"

#Build Email Content

    #build User
$Searcher = [adsisearcher]"(samaccountname=$env:USERNAME)"
    $User = [String]$searcher.FindOne().Properties.mail
    if($user -eq $null ) { $user = ($CompName + "@grcc.edu") }

$Subject = ("Installation Failure on " + $CompName)

$message = @(
    "Name:`t $CompName `n"
    "AssetTag:`t $assettag `n"
    "Serial#:`t $sn `n"
    "Model:`t $model `n"
    "Make:`t $make `n"
    "OS:`t $OS `n"
    "Type:`t $type `n"
    "Submitter:`t $user"
    )

$file = "$env:SystemRoot\ccm\logs\AppEnforce.log"

}
Catch{ Write-host "Failed to collect data with error: $Error" }

Try{ Send-Email -smtpTo "jojohnson@grcc.edu" -smtpFrom $User -Subject $Subject -smtpCC "jojohnson@grcc.edu" -message "$message" -file $file }
Catch{Write-Host "Failed to email report with error: $Error" }

