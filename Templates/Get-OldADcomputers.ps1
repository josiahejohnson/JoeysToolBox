$date = [DateTime]::Today.AddDays(-90)
$ou = “OU=Office,OU=Workstations,DC=ad,DC=grcc,DC=edu”
Get-ADComputer -Filter  ‘PasswordLastSet  -le $date’ -SearchBase $ou -properties PasswordLastSet | Sort PasswordLastSet -Descending | FT Name,PasswordLastSet -AutoSize
