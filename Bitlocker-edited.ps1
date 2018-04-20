<#
.SYNOPSIS
	Bitlock encryption and key backup process
.DESCRIPTION
    Verifys the encrytion level of a system, encrypts new systems, updates recovery information, and verifies current records. 
.Notes
    Return Codes
    200 - "Unable to encrypt disk. Unknow error."
    210 - "Unable to backup the recovery key. Network path unreachable."
    220 - "TPM is not present or not configured"
    230 - "Unknown Error occured. Key not backedup to master file."
    240 - "Unable to create recovery password; because x" 
    250 - "Unable to encrypt volume; because x"
    
    0 - "No errors"
    3010 - "No errors. Restart Required"
#>

#region Getinfo
    
    $ServiceTag = (gwmi win32_SystemEnclosure).SMBIOSASSETTAG | Select -Unique
    $sn = (gwmi win32_bios).SerialNumber
    $cn = "$env:COMPUTERNAME"
    $date = get-date -Format "ddMMMyyyy HH:mm:ss"
    $week = get-date -UFormat %V
    
    $filepath = ##"\\server\path"##
    $masterCSV = "$filepath\CSVfiles\MasterLog.CSV"
    $weekCSV = "$filepath\csvfiles\BitLockerUpdate_week_$($Week).csv"

#endregion


#region Build Output Object
        $out = new-object PSObject
        If($ServiceTag -ne $null){$out | add-member NoteProperty ServiceTag $ServiceTag}
            Else { $out | add-member NoteProperty ServiceTag "No Asset Information" }
        $out | add-member NoteProperty SerialNumber $sn
        $out | add-member NoteProperty DateRecord $date

#endregion


#region Detection

##Check TPM
If((Get-WmiObject win32_tpm -Namespace root\cimv2\Security\MicrosoftTPM).isenabled() | Select-Object -ExpandProperty IsEnabled)
    { $TPMEnabled = $true }

##Check Volume
$WMIVolumeC= Get-WmiObject -namespace "Root\cimv2\security\MicrosoftVolumeEncryption" -ClassName "Win32_Encryptablevolume" -filter "DriveLetter = '$($env:SystemDrive)'"

##Check encryption
If(($WMIVolumeC.ProtectionStatus -eq 1) -and ($TPMEnabled) -and ($WMIVolumeC.IsVolumeInitializedForProtection))
    {
        $Verify = $true
    }
ElseIf(Test-Path $filepath)
    {
        Write-Host "Unable to backup the recovery key. Network path unreachable."
        exit 210
    }
ElseIf((!$TPMEnabled))
    {
        Try
            { 
                Write-host "TPM is not configured. Attempting to provision TPM"
                $TPM = Enable-TpmAutoProvisioning -Verbose -ErrorAction Stop 
                Write-Host "TPM provisioning successful. Restart Required"
                exit 3010
            }
        Catch
            {
                Write-host "TPM is not present or failed to configure"
                exit 220
            }
    }
ElseIF(($WMIVolumeC.ProtectionStatus -ne 1) -or (!$WMIVolumeC.IsVolumeInitializedForProtection))
    {
        $Encrypt = $true
    }
Else
    {
        Write-Host "Unable to encrypt disk. Unknow error."
        exit 200
    }

#endregion

#region Encrypt Disk

If($Encrypt)
    {
        Try
            {
            ## Build recovery password
                $recovery = manage-bde.exe -protectors -add c: -recoveryPassword | Out-Null
                Write-Host "Recovery Password Protector Setup Successful"
            }
        Catch
            {
                Write-host "Unable to create recovery password"
                Write-Host "$recovery"
                exit 240
            }

        Try
            {
            ## Enable BitLocker Encryption
                $Bitlocker = Enable-BitLocker -MountPoint $env:SystemDrive -EncryptionMethod Aes256 -EA Stop
                Write-Host "Enabled Bitlocker Successfully"
            }
        Catch
            {
                Write-host "Unable to encrypt volume"
                Write-Host "$Bitlocker"
                Exit 250
            }

        Write-host "Bitlocker enabled successfully"
        $verify = $true


}

#endregion


#region Verify

If($verify)
    {
        Write-host "System properly encrypted: Verifying recovery key backup is current"
        ##Get current Key
        $recovery = (manage-bde -protectors $env:SystemDrive -get -Type recoverypassword) 

        $bdeID = ($recovery | Select-String -Pattern '\{.{8}').ToString().Trim().Substring(4,38)
        $bdePass = ($recovery | Select-String -Pattern  '\d{6}-\d{6}$').ToString().Trim()


        #update output Object
        $out | add-member NoteProperty RecoveryID $bdeID
        $out | add-member NoteProperty RecoveryPassword $bdePass
        

        ##Get file and csv value
        If(!(Test-path "$filepath\keybackup\$($CN)_$bdeID.txt"))
            {
                Try
                    {
                    New-Item -Path "$filepath\keybackup" -Name "$($CN)_$bdeID.txt" -ItemType File -Value $out -Force -ErrorAction Stop | Out-Null
                    Write-Host "Key backup file already exists"
                    }
                Catch
                    {
                    Write-Host "Unable to create backup file: $filepath\keybackup\$($CN)_$bdeID.txt"
                    }
            }
        Else{Write-host "Backup file already exists at $filepath\keybackup\$($CN)_$bdeID.txt "}
        
        ## Update CSV Master Log
        $importedCSV = Import-Csv -Path "$masterCSV" -Delimiter ','
        $recorded = $false

        Foreach($a in $importedCSV)
                {
                If(($a.SerialNumber -eq $out.SerialNumber) -and 
                        ($a.RecoveryID -eq $out.RecoveryID) -and 
                            ($a.RecoveryPassword -eq $out.RecoveryPassword))
                    {
                    $recorded = $true
                    break
                    }
                }

        If($recorded)
            {
                Write-Host "Master Record is up to date"
                $check = ($importedCSV | where {$_.serialnumber -eq $out.SerialNumber} | Select -ExpandProperty $_).daterecord | Get-DAte -UFormat %V
                If(Test-Path "$filepath\csvfiles\BitLockerUpdate_week_$($check).csv")
                {
                    $checkCSV = Import-Csv "$filepath\csvfiles\BitLockerUpdate_week_$($check).csv" -Delimiter ','
                    Foreach($a in $checkCSV)
                        {
                        If(($a.SerialNumber -eq $out.SerialNumber) -and 
                            ($a.RecoveryID -eq $out.RecoveryID) -and 
                                ($a.RecoveryPassword -eq $out.RecoveryPassword))
                            {
                            Write-Host "Record Found in $filepath\csvfiles\BitLockerUpdate_week_$($check).csv"
                            break
                            }
                        }
                 }
                 Else
                 {
                    Write-host "No Matching week csv record Found"
                 }
                
            }
        ElseIF(!$recorded)
            {
                Write-Host "No Record Found"
                $out | Export-Csv -Path "$masterCSV" -Delimiter ',' -NoTypeInformation -Append -NoClobber
                Write-Host "Master Record Created"

                If(!(Test-Path $weekCSV))
                    {
                        Write-host "Creating at $weekCSV"
                        $out | Export-Csv -path $weekCSV -Delimiter ',' -NoTypeInformation
                        Write-host "Record added to $weekCSV"
                    }
                Else
                    {
                        Write-host "Found CSV at $weekCSV"
                        $out | Export-Csv -Path "$weekCSV" -Delimiter ',' -NoTypeInformation -Append -NoClobber
                        Write-host "Record added to $weekCSV"
                    }
            }
        Else
            {
                Write-Host "Unknown Error occured. Key not backedup to master file."
                exit 230
            }

}

#endregion