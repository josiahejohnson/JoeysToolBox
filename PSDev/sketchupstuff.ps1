$path1 = "$env:PUBLIC\desktop\Sketchup 2015.lnk"
$path2 = "$env:PUBLIC\desktop\Style Builder 2015.lnk"
$path3 = "$env:PUBLIC\desktop\LayOut 2015.lnk"

If(test-path $path1) { Remove-Item -Path $path1 -Force }
If(test-path $path2) { Remove-Item -Path $path2 -Force }
If(test-path $path3) { Remove-Item -Path $path2 -Force }

write-host "compliant"


$path = "$env:ProgramData\sketchup\sketchup 2015\activation_info.txt"
If(test-Path $path){write-host "Compliant"}

Else{ 
$file = "\\cold.grcc.edu\sccm\apps\google\Sketchup\2015\activation_info.txt"
If(Test-Path $file)
    { 
        Copy-Item $file -Destination $path -Force 
        Write-host "Compliant"    
    }
    Else{Write-Host "Couldn't Find Activation File"}
 }
