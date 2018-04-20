$path = "$env:ProgramData\Microsoft\Windows\Start Menu"

$current = Get-ChildItem -Recurse $path

[Array]$Remove = @(
"$path\Programs\Games\"
"$path\Windows Update.lnk"
"$path\Programs\embedded Lockdown Manager\"
"$path\Programs\Accessories\Getting Started.lnk"
"$path\Programs\Accessories\Sync Center.lnk"
"$path\Programs\Maintenance\"
)

Foreach($Shortcut in $Remove)
    {
    If(Test-path $Shortcut)
        {
        Try{ Remove-Item -Path $Shortcut -Recurse -Force -ErrorAction Continue }
        Catch{ Write-Host $Error }
        }
    }

[Array]$Media = @(
"$path\Programs\Media Center.lnk"
"$path\Programs\Windows Movie*"
"$path\Programs\Windows Media*"
"$path\Programs\Windows DVD*"
)

Foreach($Shortcut in $Media)
    {
    If(Test-path $Shortcut)
        {
        Try{ Move-Item $Shortcut -Destination "$path\Programs\Media\" -Force -ErrorAction Continue }
        Catch{ Write-Host $Error }
        }
    }

[Array]$Accessories = @(
"$path\Programs\java\"
"$path\Programs\Microsoft Silverlight\"
"$path\Programs\SideBar.lnk"
"$path\Programs\Windows Fax*"
"$path\Programs\XPS Viewer*"
)

If(!(Test-Path "$path\programs\media"))
    { New-Item -Path "$path\Programs\" -Name Media -ItemType Directory -Force}

Foreach($Shortcut in $Accessories)
    {
    If(Test-path $Shortcut)
        {
        Try{ Move-Item $Shortcut -Destination "$path\Programs\Accessories\" -Force -ErrorAction Continue }
        Catch{ Write-Host $Error }
        }
    }