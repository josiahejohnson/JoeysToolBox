    # Set $owner to Admin
$owner = [System.Security.Principal.NTAccount]"Administrators"

If ( Get-PSDrive -Name HKLM )
    {
        # Directory to key to be updated
    $key = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey("SOFTWARE\Classes\CLSID\{20D04FE0-3AEA-1069-A2D8-08002B30309D}",[Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree,[System.Security.AccessControl.RegistryRights]::ChangePermissions)
    #$key = 'HKLM:\SOFTWARE\Classes\CLSID\{20D04FE0-3AEA-1069-A2D8-08002B30309D}'

        # set ACLs
    $acl = get-acl $key
$acl = $key.GetAccessControl()

        # Set key owner to Admin and update permissions
    If($acl.Owner -notlike 'Builtin\' + $owner)
        {
            $acl.setowner($owner)
            #$rule = New-Object System.Security.AccessControl.RegistryAccessRule($owner,"FullControl","Allow")
            #$acl.SetAccessRule($rule)
            $acl | Set-Acl -Path $key
        }

        # Set key value to %computername%
    If((Get-ItemProperty $key).LocalizedString -Notlike $env:COMPUTERNAME)
        {
            $key | Rename-ItemProperty -Name 'LocalizedString' -NewName 'LocalizedString.old'
            New-ItemProperty -Path $key -Name 'LocalizedString' -PropertyType ExpandString -Value "%COMPUTERNAME%"
        }
    }