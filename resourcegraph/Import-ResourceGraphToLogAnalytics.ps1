#Requires -Modules Az.Accounts, Az.ResourceGraph

param (
    [Parameter(Mandatory = $true)]
    [string]$Query,
    [Parameter(Mandatory = $true)]
    [string]$ManagementGroupIdToCheck,
    [Parameter(Mandatory = $true)]
    [string]$LogType, # Specify the name of the record type that you'll be creating
    [Parameter(Mandatory = $true)]
    [string]$CustomerId  # Replace with your Workspace ID
)

# Run Resource Graph

$ErrorActionPreference = "Stop"

$sharedKey = Get-AutomationVariable law_sharedkey

try{
	Connect-AzAccount -Identity | Out-Null
}catch{
	throw "The script execution failed with Error `n`t $($($_.Exception).Message)"
}
Write-Output "Start to query Microsoft Resource Graph..."
$result = @()
try{
	do {
		$previousResult = Search-AzGraph -Query $Query -ManagementGroup $ManagementGroupIdToCheck -SkipToken $previousResult.SkipToken
		$result += $previousResult
	} until (-not $previousResult.SkipToken)
	Write-Output "Found $($result.count) results"
	Write-Output "Finished to query Microsoft Resource Graph..."
}catch{
	throw "The script execution failed with Error `n`t $($($_.Exception).Message)"
}

# Create the function to create the authorization signature
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

# Create the function to create and post the request
Function Post-LogAnalyticsData($customerId, $sharedKey, $body, $logType)
{
    $method = "POST"
    $contentType = "application/json"
    $resource = "/api/logs"
    $rfc1123date = [DateTime]::UtcNow.ToString("r")
    $contentLength = $body.Length
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

    $response = Invoke-WebRequest -Uri $uri -Method $method -ContentType $contentType -Headers $headers -Body $body -UseBasicParsing
    return $response.StatusCode

}

try{
	Write-Output "Start to import Microsoft Resource Graph data to Log Analytics ..."
	# Submit the data to the API endpoint
	Post-LogAnalyticsData -customerId $customerId -sharedKey $sharedKey -body (($result | ConvertTo-Json -Depth 10)) -logType $logType 
	Write-Output "Finished import Microsoft Resource Graph data to Log Analytics ..."
}catch{
	throw "The script execution failed with Error `n`t $($($_.Exception).Message)"
}