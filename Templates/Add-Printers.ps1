$printers = "\\Papercut\Find_Me_BW","\\Papercut\Find_Me_Color"
$x86path = "\\cold.grcc.edu\sccm\Printers\32-Bit_Find_Me"
$installer = "\\cold.grcc.edu\sccm\printers\_Papercut_client"
$net = new-Object -com WScript.Network
$OSArch = gwmi win32_operatingsystem | select OSArchitecture


If($OSArch -match "64-bit")
    {
        $installDir = "${env:ProgramFiles(x86)}\PaperCut MF Client"
        foreach($p in $printers)
            {
                $net.AddWindowsPrinterConnection($p)
            }
        $net.SetDefaultPrinter('\\papercut\Find_ME_BW')
        If(!(Test-Path $installDir))
            {
                $install = & "$env:windir\system32\msiexec.exe" /i"$installer\client-local-install.exe" /qn
            }
    }
Else
    {
        $installDir = "$env:ProgramFiles\PaperCut MF Client"
        $drivers = & "$env:windir\system32\pnputil.exe" /add-driver "$x86path\Drivers\*.inf" /subdirs /install
        foreach($p in $printers)
            {
                $net.AddWindowsPrinterConnection($p)
            }
        $net.SetDefaultPrinter('\\papercut\Find_ME_BW')
        If(!(Test-Path $installDir))
            {
                $install = & "$env:windir\system32\msiexec.exe" /i"$installer\client-local-install.exe" /qn
            }
        $key = New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Name "PaperCut" -PropertyType ExpandString -Value '"C:\Program Files\PaperCut MF Client\pc-client.exe" --silent --minimized --neverrequestidentity --windowposition bottom-right --windowtitle {0}' -Force
    }



