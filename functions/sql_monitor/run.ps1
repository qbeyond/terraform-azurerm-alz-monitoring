<#
.SYNOPSIS
    Retrieving Monitoring Data and sending it to our Event Pipeline.
.DESCRIPTION
    This script regularly checks SQL Servers for availability and sends the retrieved data to our Event Pipeline.

    Requirements
    - Managed identity must be permitted on the keyvault
    - Managed identity needs tenant-wide read permissions

    Procedure
    - Get all DBs managed by qbeyond
    - Get keyvault name (environment variable set by Terraform)
    - Get connection strings from keyvault
    - For all connection strings: try to connect to db
        - If connection failed: try a total of 3 times before sending a CRITICAL event
    - Make sure all DBs in tenant are being monitored

    Outputs
    - Login successful -> return OK
    - Login failed -> return CRITICAL
    - Database has no connection string -> return WARNING

    Edge Cases
    - connect to DB timeout -> return CRITICAL
    - Event Pipeline not reachable -> ?
    - Wrong SQL credentials -> return CRITICAL with error info
    - No permissions (managed identity not working) -> ?
.EXAMPLE
#>

param(
    $Timer
)

#region helper_functions
function Get-QbyDatabasesInTenant {
    param ()

    Write-Host "Search tenant for MSSQL databases ..."

    # Go to the resource graph and get databases via Kusto query
    $query = @"
Resources
| where type =~ 'microsoft.sql/servers/databases'
| extend server = tostring(split(id, "/")[8]), name = tostring(split(id, "/")[10])
| where tags['alerting'] == 'enabled'
| where tags['managedby'] == 'q.beyond'
| project name, server, id
"@
    $databases = Search-AzGraph -Query $query -ManagementGroup $env:ROOT_MANAGEMENT_GROUP_ID -AllowPartialScope

    # AzGraph returns a list, but we want a map for faster search and deletion
    $dbMap = @{}
    foreach ($db in $databases) {
        $key = "$($db.name).$($db.server)"
        $dbMap[$key] = $db
    }
    return $dbMap
}

function Get-PlainTextSecret {
    param (
        [Parameter(Mandatory = $true)]
        [string]$SecretName
    )

    $secret = Get-AzKeyVaultSecret $env:SQL_MONITORING_KEY_VAULT -Name $SecretName
    # Convert from secret string to string
    return [System.Net.NetworkCredential]::new("", $secret.SecretValue).Password
}

function Get-DatabaseFromConnectionString {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ConnectionString
    )

    # Returns "[name].[server]" of database
    $ConnectionString -match "Server=tcp:(.*?).database.windows.net.*?Initial Catalog=(.*?);" | Out-Null; 
    return "$($Matches[2]).$($Matches[1])"
}

function Test-DatabaseConnection {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ConnectionString
    )

    Write-Host "Testing one database connection ..."

    $connection = New-Object System.Data.SqlClient.SqlConnection
    $result = $false
        
    $connection.ConnectionString = $ConnectionString

    try {
        $connection.Open()
        if ($connection.State -eq "Open") {
            $result = $true
        }
        else {
            throw "Wrong connection state: $($connection.State)"
        }
    }
    catch {
        throw $_
    }
    finally {
        # Ensure the connection is closed
        if ($connection.State -ne "Closed") {
            $connection.Close()
        }
    }
    return $result
}

# TODO: Real monitoring logic
function Send-MonitoringEvent {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        [string]$Severity = "TRACE"
    )
    Write-Host "[$Severity] $Message"
}
#endregion helper_functions

function Invoke-DatabaseMonitoring {
    param()

    Connect-AzAccount -Identity
    $dbs = $(Get-QbyDatabasesInTenant)

    try {
        $con_strings = Get-AzKeyVaultSecret $env:SQL_MONITORING_KEY_VAULT -ErrorAction Stop
    }
    catch {
        Send-MonitoringEvent -Message "Cannot access sql connection strings from keyvault: $($_.Exception.Message)"
        $con_strings = @()
    }
    $error_string = ""
    $success = $false

    foreach ($con in $con_strings) {
        $con = Get-PlainTextSecret -SecretName $con.Name

        # TODO: Retry loop for all dbs, not per db
        for ($iTries = 0; $iTries -lt 3; $iTries++) {
            try {
                $success = Test-DatabaseConnection -ConnectionString $con
                if ($success) { break }
            }
            catch {
                $error_string = $_.Exception.Message
                Write-Host "Error while accessing database"
                Write-Host $_.Exception.Message
                # Sleep 1 minute before retrying
                if ($iTries -lt 2) {
                    Write-Host "Trying again in 60s"
                    Start-Sleep -Seconds 60
                }
            }
        }
        
        if ($success) {
            Send-MonitoringEvent -Message "Connection successful" -Severity "OK"
        }
        else {
            Send-MonitoringEvent -Message $error_string -Severity "CRITICAL"
        }

        # Database has been monitored, remove from tenant-wide list
        $dbKey = Get-DatabaseFromConnectionString $con
        if (![string]::IsNullOrWhiteSpace($dbKey) -and $dbs.ContainsKey($dbKey)) {
            Write-Host $dbKey
            $dbs.Remove($dbKey)
        }
    }

    # Go over remaining list of unmonitored databases
    foreach ($db in $dbs.GetEnumerator()) {
        Send-MonitoringEvent -Message "Database is not being monitored! $($db.Value.Id)" -Severity "WARNING"
    }
}

Invoke-DatabaseMonitoring
Write-Host $env:WEBSITE_PRIVATE_IP