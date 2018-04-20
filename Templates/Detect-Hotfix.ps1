$Result = Get-Hotfix | where { $_.hotfixid -eq 'KB2506143' }
If ($Result) { Write-Host $true }