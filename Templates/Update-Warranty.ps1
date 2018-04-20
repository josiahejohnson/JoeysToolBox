
Function Get-LenovoWarranty {
    [CmdletBinding()]
    param(
        [parameter(Mandatory=$false)]
        [string]$serial 
        )

If( !$serial ){$serial = (GWMI win32_Bios).serialnumber }

$test = Invoke-WebRequest -uri http://support.lenovo.com/us/en/warrantylookup
$form = $test.forms[0]
$form.Fields["serialCode"]="$($serial)"
$answer = Invoke-WebRequest -Uri ("http://support.lenovo.com" + $form.Action) -WebSession $ln -Method $form.Method -Body $form.Fields
$return = ($answer.ParsedHtml.getElementById("warranty_result_div").outerText).replace(": ","=")

$output = ConvertFrom-StringData -StringData $return


Write-Output ($output.GetEnumerator() | Sort -Property Name)

}


Function Update-WarrantyInfo {

$Results = Get-LenovoWarranty


$key = "HKLM:\SOFTWARE\GRCC\WarrantyInformation"

If( !(Test-Path $key) )
    { 
        Try 
            { $return = New-item -Path $key -ItemType Key -Force -ErrorAction Stop }
        Catch
            { $output = "Error: $($Error[0].exception.message)" }
    }

Foreach($r in $Results)
    { 
        Try
            { $return = New-ItemProperty -Path $key -Name "$($r.Name)" -Value "$($r.Value)" -PropertyType String -Force -ErrorAction Stop }
        Catch
            { $output = "Error: $($Error[0].exception.message)" }
    }

If(!($output))
    { $output = "Compliant" }

Write-Output $output
}