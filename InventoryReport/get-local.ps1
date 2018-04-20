Function Get-Local {
[CmdLetBinding()]

    Param(
        [Parameter(ValueFromPipeLine = $True)]
        [String[]]$CN = $env:COMPUTERNAME
        )

    Process{
#output Array
     $Inventory = "" | Select-Object -Property ComputerName,SerialNumber,ModelNumber,AssetTag,AssignedUser

#get-values
            [string]$SN = (gwmi -cn $CN win32_bios).SerialNumber
            [string]$Model = (gwmi -cn $CN win32_computersystem).model


            $InvReg = "HKLM:\SOFTWARE\GRCC\Inventory"

            If(Get-ItemPropertyValue -Path $InvReg -Name AssetTag)
                {  $AssetTag = Get-ItemPropertyValue -Path $InvReg -Name AssetTag  }
            Else
                {  $AssetTag = "NotSet" }

            $WrnReg

            $Warrenty

            $AssignedUser = (gwmi -cn $cn -Namespace root/ccm/policy/machine -Class CCM_UserAffinity).consoleUser


#build inventory
            $Inventory.ComputerName = "$CN"
            $inventory.SerialNumber = "$SN"
            $inventory.ModelNumber = "$Model"
            $Inventory.AssetTag = "$AssetTag"
            $Inventory.AssignedUser = "$AssignedUser"

        #output
        return $Inventory | select *

        }
        

        }