Try{

[String]$comp = $env:computerName

[ADSI]$Admin="WinNT://$comp/Administrator"


## Enable Admin account with preferred settings
If($admin.UserFlags -ne 66113)
    { $admin.UserFlags = 66113 }

## Set Password
$Admin.SetPassword("sn0ZZB3rr13s")

## Commit Changes
$admin.setinfo()


## Update Registry to reflect date of change.
$regpath = "HKLM:\SOFTWARE\GRCC"
$regKey = "$regpath\Admin"

If(!(Test-Path $regpath)){ New-Item -Path $regpath -ItemType Key  }
If( !(Test-path $regKey)){ New-Item -Path $regKey -ItemType Key  }

$Version = "April16"
$Changed = ( Get-Date -Format MM/dd/yyyy )

Try{ 
    New-ItemProperty -Path $regkey -Name "Version" -PropertyType String -Value $Version -Force 
    }Catch{ exit }

Try{
    New-ItemProperty -Path $regkey -Name "Changed" -PropertyType String -Value $Changed -Force 
    }Catch{ exit }


Write-Host "Compliant"


}Catch{ exit }