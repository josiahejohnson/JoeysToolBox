$ErrorActionPreference = "Continue"

    # Start GPUpdate as background job
$gpo = (Start-Job -ScriptBlock { gpupdate /force /wait:0 } -Name 'GPUpdate' -ErrorAction 'Continue')

    # Start SCCM Refresh
$SMSCli = [wmiclass] "\\$env:computername\root\ccm:SMS_Client"

Try{
    $SMSCli.RequestMachinePolicy()
    $SMSCli.EvaluateMachinePolicy()
    $exitcode = "0"
    }
    Catch{
    Write-host $Error
    $exitcode = "1"
    }

Wait-Job $gpo
If($gpo.JobStateInfo.State -ne "Completed")
    { 
    If($exitcode -eq "1" ) { $exitcode = "3" }
    Else { $exitcode = "2" }
    }
Remove-Job $gpo
    <#
    Exit codes
        0 = Successful
        1 = Problem with SCCM Refresh
        2 = Problem with GPUpdate
        3 = Problem with SCCM Refresh and GPUpdate
    #>
exit $exitcodes