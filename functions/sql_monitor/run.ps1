<#
.SYNOPSIS
    Retrieving Monitoring Data and sending it to LAW.
.DESCRIPTION
    This script regularly checks SQL Servers for availability and sends the retrieved data to Log Analytics Workspace.

    Requirements
    - Managed identity must be permitted on both keyvault

    Procedure
    - Get all DBs managed by qbeyond
    - Get keyvault name from Terraform
    - Get connection strings from keyvault
    - For all connection strings: try to connect to db
    - Make sure all DBs in tenant are being monitored

    Outputs
    - Login successful -> return OK
    - Login failed -> return CRITICAL
    - Database has no connection string -> return CRITICAL

    Edge Cases
    - connect to DB timeout -> return CRITICAL
    - LAW not reachable -> ?
    - Wrong SQL credentials -> return CRITICAL with error info
    - No permissions (managed identity not working) -> return CRITICAL with error info
.EXAMPLE
#>

param(
    $Timer
)

# # 1. Get all DBs in tenant (that are managed by qbeyond)

# 2. Get all connection strings
Connect-AzAccount -Identity
$keys = Get-AzKeyVaultSecret $env:SQL_MONITORING_KEY_VAULT

# 3. Connect to all connection strings
foreach ($key in $keys) {
    $password = Get-AzKeyVaultSecret $env:SQL_MONITORING_KEY_VAULT -name $key.Name
    $password = [System.Net.NetworkCredential]::new("", $password.SecretValue).Password
    $connection = New-Object System.Data.SqlClient.SqlConnection
    Write-Host $password
    
    $connection.ConnectionString = $password

    try {
        $connection.Open()
    
        if ($connection.State -eq "Open") {
            Write-Host "✅ Connection successful!"
        } else {
            Write-Host "⚠️ Connection state: $($connection.State)"
        }
    }
    catch [System.Data.SqlClient.SqlException] {
        Write-Host "❌ SQL Exception: $($_.Exception.Message)"
    }
    catch {
        Write-Host "❌ General Error: $($_.Exception.Message)"
    }
    finally {
        # Ensure the connection is closed
        if ($connection.State -ne "Closed") {
            $connection.Close()
            Write-Host "🔒 Connection closed."
        }
    }
    
    # c. Remove DB from list of all DBs in tenant
}

# # 4. Check the remaining list of all dbs in tenant
# foreach ($db in $tenant_dbs) {
#     # Failure -> DB is not being monitored
# }

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