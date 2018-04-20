<#
	.DESCRIPTION
		This script creates a file with a list of all OU's that exist under the StartOU
	.PARAMETER FileDir
		Where the file will be created
	.PARAMETER FileName
		Name of the file to be created
	.PARAMETER StartOU
		Path to the highest OU to be output to the file
	.EXAMPLE
		Get-OUs -filedir C:\Temp\ -filename OUList.txt -StartOU domain.company.com/computers
#>

	param (
		[Parameter(ValueFromPipeline = $true)]
		[Alias("dir", "directory")]
		[String]$FileDir,
		[Parameter(ValueFromPipeline = $true)]
		[Alias("file")]
		$FileName,
		[Parameter(ValueFromPipeline = $true)]
		[Alias("OU","start")]
		$StartOU
	)
	
	If ( !($FileDir) ) { $FileDir = "$env:USERPROFILE\documents\Active Directory\" }
	If ( !($FileDir.EndsWith("\") ) ) { $FileDir = $FileDir + "\" }
	If ( !($FileName) ) { $FileName = "OUlist.txt" }
	If ( !($StartOU) ) { $StartOU = "ad.grcc.edu/Workstations" }
	
	IF (!(Test-path $FileDir)) { New-Item -ItemType 'Directory' -Force -Path $FileDir }
	
	$ous = @(); dsquery.exe ou -limit 10000000 |
	% { $_.trimstart('"').trimend('"') } |
	% {
		$_.Split(",") |
		% { switch -Wildcard ($_) { "OU=*" { $x = '/' + $_.substring(3) + $x }; "DC=*" { $y = $y + '.' + $_.substring(3) } } }; $ou = $y.TrimStart('.') + $x; $x = ''; $y = ''; $ous = $ous + $ou
	}
	
	foreach ($ou in $ous) { If ($ou.StartsWith($StartOU)) { [array]$OUList += $ou } }
	
	$OUList | Sort -Unique | Out-File ($FileDir + $fileName)