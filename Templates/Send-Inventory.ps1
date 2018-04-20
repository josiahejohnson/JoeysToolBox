#Inventory script

Function Send-Email {
[CmdLetBinding()]

    Param(
        [String]$smtpFrom = ($env:COMPUTERNAME + "@grcc.edu"),
        [String]$SMTPserv = "SMTP.GRCC.EDU",
        [String]$subject = ("Inventory-" + $env:COMPUTERNAME),
        [Parameter(ValueFromPipeLine = $True)]
        [String]$smtpTo,
        [Parameter(ValueFromPipeLine = $True)]
        [String]$message
    )

        Process{

            # Create Message
            $smtp = New-Object Net.Mail.SMTPClient ($SMTPserv)
            $SMTP.Send($smtpFrom,$smtpTo,$subject,$message)
        }
    }

$CompName = $env:COMPUTERNAME

$Searcher = [adsisearcher]"(samaccountname=$env:USERNAME)"
     $User = [String]$searcher.FindOne().Properties.mail

$comp = gwmi win32_computersystem | Select *
    $make = $comp.Manufacturer
    $model = $comp.Model

$assettag = (gwmi win32_systemenclosure).SMBIOSAssetTag
    If($assettag.Length -lt 6){ $assettag = Read-Host -Prompt "Please enter asset tag"  }

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

$local = "`"" + (read-host -Prompt "Please enter Location") + "`""

$message = @(
    "Name:`t $CompName `n"
    "AssetTag:`t $assettag `n"
    "Serial#:`t $sn `n"
    "Model:`t $model `n"
    "Make:`t $make `n"
    "OS:`t $OS `n"
    "Type:`t $type `n"
    "Location:`t $local `n"
    "Submitter:`t $user"
    )
    

Send-Email -smtpTo "jefferyvanderveen@grcc.edu" -message "$message"