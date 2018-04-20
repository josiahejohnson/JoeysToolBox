$domain = "AD.GRCC.EDU"
$baseOU = "OU=AutoRepaired,OU=OnBoarding,OU=Workstations,DC=AD,DC=GRCC,DC=EDU"
$joinuser = "ad\SCCMAdmin"
$passWord = "01000000d08c9ddf0115d1118c7a00c04fc297eb0100000064492e90de55874b8767f9fac554ad6f0000000002000000000003660000c000000010000000c0efc83a3552b4164f4f32b8b176ad310000000004800000a000000010000000ff89f3e4cb63abbd93a54453e2549c7720000000a30e900a103a94f98d50864356ec41517d432ce0fd8f82904e5f6e2fb80b9d7c140000003975e8215730eea0714c9a14723a2a5664d14592"
$creds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $joinuser,( $passWord | ConvertTo-SecureString )
[string]$return
[int]$exit

If(!(Test-ComputerSecureChannel))
    {
        Try{
            $return = Test-ComputerSecureChannel -Repair -Server $domain -Credential $creds -ErrorAction Stop
            If(!$return)
                {
                    $return = Reset-ComputerMachinePassword -Server $domain -Credential $creds -ErrorAction Stop
                }
            $return = "Reset Successful"
            $exit = 0
        }Catch{
                Try{
                    Add-Computer -DomainName $domain -OUPath $BaseOU -Credential $($creds) -Force -ErrorAction Stop
                    $return = "Rejoined Domain to $BaseOU"
                    $exit = 0
                }Catch{
                    $return = $error[0].Exception.Message
                    $exit = 1
                    }
            }

    Write-Host $return
    exit $exit
 
    }