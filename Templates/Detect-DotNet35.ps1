[array]$test = ( (Invoke-Command  {Dism.exe /online /get-features /format:table}) -replace (' ') )
If( ($test).Contains('NetFx3|Enabled') ) { Write-Host $true }

