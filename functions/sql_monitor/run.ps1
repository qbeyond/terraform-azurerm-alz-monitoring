<#
.SYNOPSIS
    Retrieving Monitoring Data and sending it to our Event Pipeline.
.DESCRIPTION
    This script regularly checks MSSQL databases for availability and sends the retrieved data to our Event Pipeline.

    Requirements
    - Managed identity must be permitted on the keyvault
    - Managed identity needs tenant-wide read permissions

    Procedure
    1. Get all DBs managed by qbeyond
    2. Get connection strings from keyvault (keyvault information from environment variable set by terraform deployment)
    3. For all connection strings: try to connect to db
        If connection failed: try a total of 3 times before sending a CRITICAL event
    4. For all remaining databases in tenant
        Send a warning, because we are currently not monitoring those databases.
#>

param(
    $Timer
)

#region helper_functions
function Get-QbyDatabasesInTenant {
    param ()

    Write-Host "Search tenant for MSSQL databases ..."

    # Go to the resource graph and get databases via Kusto query
    #     $query = @"
    # Resources
    # | where type =~ 'microsoft.sql/servers/databases'
    # | extend server = tostring(split(id, "/")[8]), name = tostring(split(id, "/")[10])
    # | where tags['alerting'] == 'enabled'
    # | where tags['managedby'] == 'q.beyond'
    # | project name, server, id
    # "@
    $query = @"
Resources
| where type =~ 'microsoft.sql/servers/databases'
| extend server = tostring(split(id, "/")[8]), name = tostring(split(id, "/")[10])
| project name, server, id
"@
    $databases = Search-AzGraph -Query $query -ManagementGroup $env:ROOT_MANAGEMENT_GROUP_ID -ErrorAction Stop

    # AzGraph returns a list, but we want a map for faster search and deletion
    # Key = "[name].[server]"
    $dbMap = @{}
    foreach ($db in $databases) {
        $key = "$($db.name).$($db.server)"
        $dbMap[$key] = $db
    }
    return $dbMap
}

function Get-PlainTextSecrets {
    param (
        [Parameter(Mandatory = $true)]
        [string]$KeyVault
    )

    Write-Host "Getting connection strings from keyvault ..."

    try {
        return Get-AzKeyVaultSecret $KeyVault | Foreach-Object {
            $secret = Get-AzKeyVaultSecret $KeyVault -Name $_.Name
            [System.Net.NetworkCredential]::new("", $secret.SecretValue).Password
        }
    } catch {
        throw $_
    }
}

function Get-DatabaseFromConnectionString {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ConnectionString
    )

    # Returns "[name].[server]" of database
    if ($ConnectionString -match "Server=tcp:(.*?).database.windows.net.*?Initial Catalog=(.*?);") { 
        return "$($Matches[2]).$($Matches[1])"
    }
    return ""
}

function Test-DatabaseConnection {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ConnectionString
    )

    Write-Host "Testing one database connection ..."

    $connection = New-Object System.Data.SqlClient.SqlConnection
    $connection.ConnectionString = $ConnectionString

    try {
        $connection.Open()
        if ($connection.State -ne "Open") {
            throw "Wrong connection state: $($connection.State)"
        }
    } catch {
        throw $_
    } finally {
        # Ensure the connection is closed
        if ($connection.State -ne "Closed") {
            $connection.Close()
        }
    }
    # If the function did not throw, everything was fine
    return $true
}

function Invoke-DatabaseMonitoring {
    param()

    $dbs = Get-QbyDatabasesInTenant

    try {
        $con_strings = Get-PlainTextSecrets -KeyVault $env:SQL_MONITORING_KEY_VAULT -ErrorAction Stop
    } catch {
        # TODO: Function App CI
        Send-TimedMonitoringEvent -Message "Cannot access sql connection strings from keyvault: $($_.Exception.Message)"`
            -State "CRITICAL"`
            -ResourceID "n/a"`
            -AffectedEntity "SQL Monitoring Connectionstrings"`
            -AffectedObject $env:SQL_MONITORING_KEY_VAULT`
            -Timespan "00:02:00"

        $con_strings = @()
    }

    $db_errors = @{}
    for ($iTries = 0; $iTries -lt 3; $iTries++) {
        $failed_dbs = @()
        foreach ($con in $con_strings) {
            $dbKey = Get-DatabaseFromConnectionString $con
        
            try {
                Test-DatabaseConnection -ConnectionString $con

                if (![string]::IsNullOrWhiteSpace($dbKey) -and $dbs.ContainsKey($dbKey)) {
                    Send-TimedMonitoringEvent -Message "Connection successful"`
                        -State "OK"`
                        -ResourceID $dbs[$dbKey].Id`
                        -AffectedEntity $dbs[$dbKey].Name`
                        -AffectedObject $dbs[$dbKey].Server`
                        -Timespan "00:02:00"

                    $dbs.Remove($dbKey)
                }
            } catch {
                $failed_dbs += $con
                $db_errors[$dbKey] = $_.Exception.Message
            }
        }

        $con_strings = $failed_dbs

        # Sleep 1 minute before retrying
        if ($iTries -lt 2 -and $failed_dbs.Count -gt 0) {
            Write-Host "Trying again in 60s"
            #Start-Sleep -Seconds 60
        }
    }

    # Every remaining connection string has errored out 3 times in a row
    foreach ($con in $con_strings) {
        $dbKey = Get-DatabaseFromConnectionString $con
        if ([string]::IsNullOrWhiteSpace($dbKey) -or !$dbs.ContainsKey($dbKey)) {
            continue
        }
        
        Send-TimedMonitoringEvent -Message "Error while connecting to $dbKey - $($db_errors[$dbKey])"`
            -State "CRITICAL"`
            -ResourceID $dbs[$dbKey].Id`
            -AffectedEntity $dbs[$dbKey].Name`
            -AffectedObject $dbs[$dbKey].Server`
            -Timespan "00:02:00"

        $dbs.Remove($dbKey)
    }

    # Go over remaining list of unmonitored databases
    foreach ($db in $dbs.GetEnumerator()) {
        Send-TimedMonitoringEvent -Message "Database is not being monitored! $($db.Value.Id)"`
            -State "WARNING"`
            -ResourceID $db.Value.Id`
            -AffectedEntity $db.Value.Name`
            -AffectedObject $db.Value.Server`
            -Timespan "00:02:00"
    }
}

$MonitoringParameters = @{
    Package = "MSSQL Monitor"
    Description = "This script regularly checks MSSQL databases for availability"
    Name = "MSSQL Monitor"
    ScriptName = "sql_monitor"
    ScriptVersion = "1.0"
    ServiceUri = $env:SQL_SERVICE_URI
    BlobURL = $env:SQL_STATE
}

Initialize-QbyMonitoring @MonitoringParameters

Invoke-DatabaseMonitoring

Stop-QbyMonitoring
