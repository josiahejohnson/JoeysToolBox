$Result = (gwmi win32_printer -filter "Name LIKE 'Follow-U%(Staff)%'")
$result1 = $Result | select DriverName
If (($Result) -and ($result1 -match "4025") ) { Write-Host $true }