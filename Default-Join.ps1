

#(Get-Credential).Password | ConvertFrom-SecureString | Out-File "C:\Temp\Password.txt"


$domain = "AD.GRCC.EDU"
$baseOU = "OU=Workstations,DC=AD,DC=GRCC,DC=EDU"

$joinuser = "ad\SCCMAdmin"
$passWord = "01000000d08c9ddf0115d1118c7a00c04fc297eb0100000064492e90de55874b8767f9fac554ad6f0000000002000000000003660000c000000010000000c0efc83a3552b4164f4f32b8b176ad310000000004800000a000000010000000ff89f3e4cb63abbd93a54453e2549c7720000000a30e900a103a94f98d50864356ec41517d432ce0fd8f82904e5f6e2fb80b9d7c140000003975e8215730eea0714c9a14723a2a5664d14592"

$creds = New-Object -TypeName System.Management.Automation.PSCredential `
    -ArgumentList $joinuser,( $passWord | ConvertTo-SecureString )

$cn = "$env:COMPUTERNAME"
$L1 = $cn.Substring(0,1)
$L2 = $cn.Substring(1,3)
$L3 = $cn.Substring(4,3)
$L4 = $cn.Substring(7,1)


If($L1 -eq "O")
    {
        Try{
            $temp = "OU=$L2,OU=Office,$baseOU"
            If([adsi]::Exists("LDAP://$temp"))
                { $OU = $temp }
            }
        Catch{ $error[0].Exception.Message }
    }

ElseIf(($L1 -eq "M") -and ($L2 -ne "ini") )
    {
        Try{
            $temp = "OU=$L2,OU=MultiMedia,$baseOU"
            
            If([adsi]::Exists("LDAP://$temp"))
                { $OU = $temp }
            }
        Catch{ $error[0].Exception.Message }
    }
ElseIF($L1 -eq "L")
    {
       Try{
            $temp1 = "OU=L$L3$L4,OU=$L2,OU=Student,$baseOU"
            $temp2 = "OU=L$L3,OU=$L2,OU=Student,$baseOU"
            If([adsi]::Exists("LDAP://$temp1"))
                { $OU = $temp1 }
            ElseIF([adsi]::Exists("LDAP://$temp2"))
                { $OU = $temp2 }
            EsleIF(("$L2$L3" -eq "TMTAut") -or ("$L2$L3" -eq "TMT106") -or ("$L2$L3" -eq "TMT141"))
                { $OU = "OU=AutoBayKiosk,OU=TMT,OU=Student,$baseOU" }
            ElseIF("$L2$L3" -eq "TMTATR")
                {$OU = "OU=LWeldingTrailer,OU=TMT,OU=Student,$baseOU"}
            ElseIF($cn.Substring($cn.Length-7,7) -eq "TUTORTR")
                {$OU = "OU=TutorTrac,OU=Student,$baseOU"}
            ElseIF($cn.Substring($cn.Length-4,4) -eq "XRAY")
                {$OU = "OU=XRAY,OU=CAH,OU=Student,$baseOU"}
            ElseIF(("$l2$L3" -eq "CAH113") -or ("$l2$L3" -eq "CAH115") -or ("$l2$L3" -eq "CAH518") )
                {$OU = "OU=DevMath,OU=CAH,OU=Student,$baseOU"}
            Else{ Continue }
          }
       Catch{ $error[0].Exception.Message }
    }
Else{}


If(!$OU){$OU = "OU=Onboarding,$baseOU"}

<#
Switch($L1)
        {
        "O"{$L1 = "Office"}
        "M"{$L1 = "Multimedia"}
        "L"{$L1 = "Student"}
        default{}
        }
#>



Add-Computer -DomainName $domain -OUPath $OU -Credential $($creds) -Force -WhatIf