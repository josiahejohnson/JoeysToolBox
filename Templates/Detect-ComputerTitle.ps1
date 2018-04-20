    # Set $owner to Admin
$owner = [System.Security.Principal.NTAccount]"Administrators"

If ( Get-PSDrive -Name HKLM )
    {
        #Get Key
    $key = 'HKLM:\SOFTWARE\Classes\CLSID\{20D04FE0-3AEA-1069-A2D8-08002B30309D}'

        # Get ACLs
    $acl = get-acl $key

        # Get Key Value
    $value = (Get-ItemProperty -Path $key)

        # Check to see if key owner is Admin and that string is correct Value
    If( $acl.Owner -notlike 'Builtin\' + $owner ) { Write-Host "Non-Compliant" }
    ElseIf($value.LocalizedString -notlike $env:COMPUTERNAME) { Write-Host "Non-Compliant" }
    Else{ Write-Host "Compliant" }

    }