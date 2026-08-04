param (
    [Parameter(Mandatory = $false)]
    [string]$LogType = "Reservations", # Specify the name of the record type that you'll be creating
    [Parameter(Mandatory = $true)]
    [string]$CustomerId  # Replace with your Workspace ID
)

# ----- Helper functions -----
Function Build-Signature ($customerId, $sharedKey, $date, $contentLength, $method, $contentType, $resource)
{
    $xHeaders = "x-ms-date:" + $date
    $stringToHash = $method + "`n" + $contentLength + "`n" + $contentType + "`n" + $xHeaders + "`n" + $resource

    $bytesToHash = [Text.Encoding]::UTF8.GetBytes($stringToHash)
    $keyBytes = [Convert]::FromBase64String($sharedKey)

    $sha256 = New-Object System.Security.Cryptography.HMACSHA256
    $sha256.Key = $keyBytes
    $calculatedHash = $sha256.ComputeHash($bytesToHash)
    $encodedHash = [Convert]::ToBase64String($calculatedHash)
    $authorization = 'SharedKey {0}:{1}' -f $customerId,$encodedHash
    return $authorization
}

Function Post-LogAnalyticsData($customerId, $sharedKey, $body, $logType)
{
    $method = "POST"
    $contentType = "application/json"
    $resource = "/api/logs"
    $rfc1123date = [DateTime]::UtcNow.ToString("r")
    $bodyBytes = [System.Text.Encoding]::UTF8.GetBytes($body)
    $contentLength = $bodyBytes.Length
    $signature = Build-Signature `
        -customerId $customerId `
        -sharedKey $sharedKey `
        -date $rfc1123date `
        -contentLength $contentLength `
        -method $method `
        -contentType $contentType `
        -resource $resource
    $uri = "https://" + $customerId + ".ods.opinsights.azure.com" + $resource + "?api-version=2016-04-01"

    $headers = @{
        "Authorization" = $signature;
        "Log-Type" = $logType;
        "x-ms-date" = $rfc1123date;
    }

    try {
        $response = Invoke-WebRequest -Uri $uri -Method $method -ContentType $contentType -Headers $headers -Body $bodyBytes -UseBasicParsing
        return $response.StatusCode
    }
    catch [System.Net.WebException] {
        # Check if the exception contains a web response
        if ($_.Exception.Response) {
            # Read the hidden response stream to get the actual API error
            $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            $reader.BaseStream.Position = 0
            $responseBody = $reader.ReadToEnd()
            
            throw "Log Analytics API rejected the request. Details: $responseBody"
        }
        else {
            throw "Web Exception occurred but no response body was available: $($_.Exception.Message)"
        }
    }
}

# ----- Main script -----
$ErrorActionPreference = "Stop"
$sharedKey = Get-AutomationVariable law_sharedkey

# Connect to Azure using Managed Identity
try {
	Connect-AzAccount -Identity| Out-Null
} catch {
	throw "The script execution failed with Error `n`t $($($_.Exception).Message)"
}

$Reservations = Get-AzReservationOrder

if (-not $Reservations) {
    return
}

$body = $Reservations | Select-Object `
    @{Name='BenefitStartTime_t';Expression={$_.BenefitStartTime}},
    @{Name='Term_s';Expression={$_.Term}},
    @{Name='ExpiryDate_t';Expression={$_.ExpiryDate}},
    @{Name='Id_s';Expression={$_.Id}},
    @{Name='ProvisioningState_s';Expression={$_.ProvisioningState}},
    @{Name='DisplayName_s';Expression={$_.DisplayName}} |
    ConvertTo-Json -Depth 5

# Write reservations to Log Analytics
Write-Output "Start collection Backup Data from the last 24 hours.."
try {
	Post-LogAnalyticsData -customerId $customerId -sharedKey $sharedKey -body $body -logType $LogType 
} catch{
	throw "The script execution failed with Error `n`t $($_.Exception)"
}
Write-Output "Finished import importing Backup date to Log Analytics ..."

