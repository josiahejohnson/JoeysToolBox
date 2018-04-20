Function Get-asset {
[CmdLetBinding()]

Param(
[Parameter(Mandatory = $true,ParameterSetName = '',ValueFromPipeline = $true)]
[string[]]$computername,

[Parameter(Mandatory = $true,ParameterSetName = '',ValueFromPipeline = $true)]
[string]$Query

)

$ErrorActionPreference = "stop"

$MySQLAdminUserName = ‘read_only’
$MySQLAdminPassword = ‘###’
$MySQLDatabase = ‘####’
$MySQLHost = ‘####’
$ConnectionString = “server=” + $MySQLHost + “;port=3306;uid=” + $MySQLAdminUserName + “;pwd=” + $MySQLAdminPassword + “;database=” + $MySQLDatabase

Try {
[void][System.Reflection.Assembly]::LoadWithPartialName(“MySql.Data”)
$Connection = New-Object MySql.Data.MySqlClient.MySqlConnection
$Connection.ConnectionString = $ConnectionString
$Connection.Open()

$Command = New-Object MySql.Data.MySqlClient.MySqlCommand($Query, $Connection)
$DataAdapter = New-Object MySql.Data.MySqlClient.MySqlDataAdapter($Command)
$DataSet = New-Object System.Data.DataSet
$RecordCount = $dataAdapter.Fill($dataSet, “data”)
$DataSet.Tables[0]
}

Catch {
Write-Host “ERROR : Unable to run query : $query `n$Error[0]”
}

Finally {
$Connection.Close()
}

}

$QS = "select assets.asset_tag as 'AssetTag',assets.name as 'ComputerName',assets.serial as 'SerialNumber',models.name as 'ModelName',models.model_number as 'ModelNumber',users.username as 'AssignedUser' from snipeit.assets
	        inner join snipeit.models
		        on assets.model_id = models.id
            inner join snipeit.users
		        on assets.assigned_to=users.id
            where assets.name like '$computername'"


Get-asset -computername (gwmi win32_computersystem).name -Query $qs

