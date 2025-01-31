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
| where tags['alerting'] == 'enabled'
| where tags['managedby'] == 'test'
| project id
"@
    # return Search-AzGraph -Query $query
    return @()
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
    return "unknown"
    # TODO: Implement function logic
}

function Remove-DatabaseFromList {
    param (
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [array]$List,
        [Parameter(Mandatory = $true)]
        [string]$Database
    )
    # TODO: Implement function logic
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
    $dbs = @($(Get-QbyDatabasesInTenant))

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

        # Try 3 times before sending error event
        for ($iTries = 0; $iTries -lt 3; $iTries++) {
            try {
                $success = Test-DatabaseConnection -ConnectionString $con
                if ($success) { break }
            }
            catch {
                $error_string = $_.Exception.Message
                # Sleep 1 minute before retrying
                # Start-Sleep -Seconds 60
            }
        }
        
        if ($success) {
            Send-MonitoringEvent -Message "Connection successful" -Severity "OK"
        }
        else {
            Send-MonitoringEvent -Message $error_string -Severity "CRITICAL"
        }

        # Database has been monitored, remove from tenant-wide list
        $dbname = Get-DatabaseFromConnectionString $con
        if (![string]::IsNullOrWhiteSpace($dbname)) {
            Remove-DatabaseFromList -List $dbs -Database $dbname
        }
    }

    # Go over remaining list of unmonitored databases
    foreach ($db in $dbs) {
        Send-MonitoringEvent -Message "Database is not being monitored!" -Severity "WARNING"
    }
}

Invoke-DatabaseMonitoring

# get sharedKey after LAW was created 
# body ?

# TODO: Make sure customerID == tenantID
# $customerId = "baee5c0e-d4cc-4c2e-b92c-fea0cff04431" #"8ab860c4-fca0-44ab-8704-faf34748c6a3"
# $sharedKey = "ITMCHcARStQZmdYKyZFf9rnr0qXrMBB1KNUjaVNiequGOyOEqRIHT2rTd1JR/Bdvyu4q3Fn7IEeMBDMfpx/whA=="
# $logType = "MonitoringResources"

# $body = @"
#     [
#         {
#             "TimeGenerated": "$(Get-Date -Format o)",
#             "TestField": "TestValue1",
#             "AnotherField": "TestValue2"
#         }
#     ]
# "@




# # Create the function to create and post the request
# function Post-LogAnalyticsData($customerId, $sharedKey, $body, $logType) {
#     $method = "POST"
#     $contentType = "application/json"
#     $resource = "/api/logs"
#     $rfc1123date = [DateTime]::UtcNow.ToString("r")
#     $contentLength = $body.Length
#     $signature = Build-Signature `
#         -customerId $customerId `
#         -sharedKey $sharedKey `
#         -date $rfc1123date `
#         -contentLength $contentLength `
#         -method $method `
#         -contentType $contentType `
#         -resource $resource
#     $uri = "https://" + $customerId + ".ods.opinsights.azure.com" + $resource + "?api-version=2016-04-01"

#     $headers = @{
#         "Authorization" = $signature;
#         "Log-Type"      = $logType;
#         "x-ms-date"     = $rfc1123date;
#     }

#     $response = Invoke-WebRequest -Uri $uri -Method $method -ContentType $contentType -Headers $headers -Body $body -UseBasicParsing
#     return $response.StatusCode
# }

# try {
#     Write-Output "Start to import Microsoft Resource Graph data to Log Analytics ..."
#     # Submit the data to the API endpoint
#     Post-LogAnalyticsData -customerId $customerId -sharedKey $sharedKey -body (($result | ConvertTo-Json -Depth 10)) -logType $logType 
#     Write-Output "Finished import Microsoft Resource Graph data to Log Analytics ..."
# }
# catch {
#     throw "The script execution failed with Error `n`t $($($_.Exception).Message)"
# }