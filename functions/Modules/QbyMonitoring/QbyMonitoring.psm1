<#  
.SYNOPSIS  
Provides functions for sending monitoring events from Azure Functions to the q.beyond event pipeline,
including initialization and sending monitoring data to a specified service.

.DESCRIPTION  
This module includes two functions:

# TODO: Update
1. Initialize-Monitoring: Initializes monitoring settings, including description, name, package, and service URI. It also parses the script name and version to set monitoring-related global settings.
2. Send-MonitoringEvent: Sends a monitoring event (OK, CRITICAL or WARNING) with additional details.

These functions facilitate integration with external monitoring systems, allowing to log and report events from within Azure Functions.

.NOTES  
Author: Mauricé Ricardo Bärisch 
Date: 2025-02-18  
Version: 1.0  
#>

function Start-QbyMonitoring {
    <#
    .SYNOPSIS  
    Initializes monitoring settings for a script.

    .DESCRIPTION  
    This function sets up the global monitoring settings, including description, name, package, and service URI.
    If the script name and version are not provided, the script name is inferred from the script's filename, and the version is extracted from the script name.

    .PARAMETER Description  
    A brief description of the monitoring script and what it aims to measure.

    .PARAMETER Name  
    The name of the monitoring configuration.

    .PARAMETER Package  
    The name of the package that this script is part of.

    .PARAMETER ServiceUri  
    The URI of the service to which monitoring data will be sent. Should be the Event Pipeline.

    .PARAMETER ScriptName  
    The name of the script. Defaults to the current script's filename.

    .PARAMETER ScriptVersion  
    The version of the script, extracted from the script name if not provided.

    .EXAMPLE  
    Initialize-Monitoring -Description "Server health check" -Name "HealthCheckScript" -Package "AZ_BS_HealthCheck" -ServiceUri "https://monitoring.example.com/api"

    .EXAMPLE  
    Initialize-Monitoring -Description "Database monitoring" -Name "DBMonitor" -Package "AZ_BS_Database" -ServiceUri "https://monitoring.example.com/api" -ScriptVersion "1.0.2"
    #>
    param(
        # Required parameters
        [Parameter(Mandatory=$true)]
        [string]$Description,

        [Parameter(Mandatory=$true)]
        [string]$Name,

        [Parameter(Mandatory=$true)]
        [string]$Package,

        [Parameter(Mandatory=$true)]
        [string]$ServiceUri,

        # Optional if script name can be parsed  
        [string]$ScriptName = (Get-Item $PSCommandPath).BaseName,

        # Optional if script version ends with [maj_version].[min_version].ps1  
        [string]$ScriptVersion = $null,

        # Optional, enables state for Send-TimedMonitoringEvent
        [string]$BlobURL = $null
    )

    function Get-BlobContent {
        param (
            [Parameter(Mandatory=$true)]
            [string]$BlobUrl
        )

        Write-Host "Retrieving state ..."
        try {
            # Get an access token for Azure Storage using Managed Identity
            $token = (Get-AzAccessToken -ResourceUrl "https://storage.azure.com/").Token

            # Call the blob storage REST API with the access token
            $headers = @{
                "Authorization" = "Bearer $token"
                "x-ms-version"  = "2025-01-05"  # Ensure compatibility with latest Storage API version
            }

            # Read the blob content into memory
            $response = Invoke-WebRequest -URI $BlobUrl -Headers $headers -Method Get
            return $response.Content
        } catch {
            Write-Error "Failed to read blob: $_"
            return $null
        }
    }

    if (-not $ScriptVersion) {
        if ($ScriptName -match "\b\d+\.\d+(\.\d+)?\b") {
            $ScriptVersion = $matches[0]
        } else {
            $ScriptVersion = "n/a"
        }
    }

    $global:QbyMonitoringSettings = @{
        SchemaId = 'FunctionApp'
        Description = $Description
        Name = $Name
        Package = $Package
        ScriptName = $ScriptName
        ScriptVersion = $ScriptVersion
        Uri = $ServiceUri
    }

    $global:stateData = @{}

    if ($null -eq $BlobURL) {
        return
    }

    $global:stateBlobURL = $BlobURL
    try {
        # Download StateData from blob
        $stateObject = Get-BlobContent -BlobURL $BlobURL | ConvertFrom-JSON

        # Turn PSCustomObject into hashtable
        $stateObject.PSObject.Properties | ForEach-Object {
            $global:stateData[$_.Name] = $_.Value
        }
    }
    catch {
        Write-Warning "Failed to retrieve state from blob: $_"
    }
}

function Send-MonitoringEvent {
    <#
    .SYNOPSIS  
    Sends a monitoring event to the configured service.

    .DESCRIPTION  
    This function sends a monitoring event with a message, state (OK, CRITICAL, WARNING), and resource ID.
    It includes optional parameters like affected entity, object, threshold, and value. The event is sent as JSON to a monitoring service,
    which is configured in the global settings initialized by the `Initialize-QbyMonitoring` function.

    .PARAMETER Message  
    The message to be sent with the event (e.g., "Service is up").

    .PARAMETER State  
    The state of the monitored resource. Valid values are "OK", "CRITICAL", or "WARNING".

    .PARAMETER ResourceID  
    The resource ID of the Azure resource being monitored.

    .PARAMETER AffectedEntity  
    The entity affected by the event (default is "n/a"). Usually contained in, or part of, the affected object.
    Example: a Database (the affected object would be Database Server)
    Example: disk space (the affected object would be the VM whose disk runs out of space)

    .PARAMETER AffectedObject  
    The object affected by the event (default is "n/a").

    .PARAMETER Threshold  
    The threshold for the monitored resource (default is "n/a").

    .PARAMETER Value  
    The value associated with the monitored resource (default is "n/a").
    The monitoring event becomes WARNING or CRITICAL, the closer the value is to the threshold.

    .EXAMPLE  
    Send-MonitoringEvent -Message "Service is running" -State "OK" -ResourceID "<AzureResourceID>"

    .EXAMPLE  
    Send-MonitoringEvent -Message "Disk space critical" -State "CRITICAL" -ResourceID "server123" -AffectedEntity "Disk C:\" -AffectedObject "CUSTDCP001" -Threshold "10%" -Value "5%"
    #>
    param(
        # Required parameters
        [Parameter(Mandatory=$true)]
        [string]$Message,

        [Parameter(Mandatory=$true)]
        [ValidateSet("OK", "CRITICAL", "WARNING")]
        [string]$State,

        [Parameter(Mandatory=$true)]
        [string]$ResourceID,

        # Optional parameters
        [string]$AffectedEntity = "n/a",
        [string]$AffectedObject = "n/a",
        [string]$Threshold = "n/a",
        [string]$Value = "n/a"
    )    

    $body = @{
        fields = @{
            TimeGenerated = (Get-Date -Format "dd-MM-yyy HH:mm")
            _ResourceID = $ResourceID
            additional_information = $Message
            affected_entity = $AffectedEntity
            affected_object = $AffectedObject
            monitor_description = $global:QbyMonitoringSettings.Description
            monitor_name = $global:QbyMonitoringSettings.Name
            monitor_package = $global:QbyMonitoringSettings.Package
            script_name = $global:QbyMonitoringSettings.ScriptName
            script_version = $global:QbyMonitoringSettings.ScriptVersion
            state = $State
            threshold = $Threshold
            value = $Value
        }
        schemaId = $global:QbyMonitoringSettings.SchemaId
    }

    $jsonString = $body | ConvertTo-Json -Depth 3

    #$headers = @{"Content-Type" = "application/json"}

    #Invoke-RestMethod -Method POST -Uri $global:QbyMonitoringSettings.ServiceUri -Body $jsonString -Headers $headers
    Write-Host $jsonString
}

function Send-TimedMonitoringEvent {
    <#
    .SYNOPSIS  
    Sends a monitoring event with rate limiting based on state changes and time intervals.

    .DESCRIPTION  
    This function ensures that monitoring events are only sent when necessary, avoiding redundant alerts.
    It compares the new event's state with the last recorded state and ensures a minimum time interval has passed.
    If both conditions are met, it calls `Send-MonitoringEvent` to send the event.

    .PARAMETER Message  
    The message to be sent with the event.

    .PARAMETER State  
    The state of the monitored resource. Valid values are "OK", "CRITICAL", or "WARNING".

    .PARAMETER ResourceID  
    The unique identifier of the monitored resource.

    .PARAMETER AffectedEntity  
    The entity affected by the event. Default is "n/a".

    .PARAMETER AffectedObject  
    The object affected by the event. Default is "n/a".

    .PARAMETER Threshold  
    The threshold for triggering monitoring alerts. Default is "n/a".

    .PARAMETER Value  
    The current value of the monitored resource. Default is "n/a".
    
    .EXAMPLE  
    Send-TimedMonitoringEvent -Message "Disk space critical" -State "CRITICAL" -ResourceID "server123" -AffectedEntity "Disk C:\" -AffectedObject "CUSTDCP001" -Threshold "10%" -Value "5%"
    #>

    param(
        # Required parameters
        [Parameter(Mandatory=$true)]
        [string]$Message,

        [Parameter(Mandatory=$true)]
        [ValidateSet("OK", "CRITICAL", "WARNING")]
        [string]$State,

        [Parameter(Mandatory=$true)]
        [string]$ResourceID,

        # Optional parameters
        [string]$AffectedEntity = "n/a",
        [string]$AffectedObject = "n/a",
        [string]$Threshold = "n/a",
        [string]$Value = "n/a",

        # Parameters needed for TimedMonitoring
        [timespan]$Timespan = "01:00:00"
    )
    
    function Test-SendEvent {
        param(
            [Parameter(Mandatory=$true)]
            [string]$ResourceID,
            [Parameter(Mandatory=$true)]
            [string]$State,
            [Parameter(Mandatory=$true)]
            [timespan]$Timespan
        )

        if ($null -eq $global:stateData) {
            $global:stateData = @{}
            return $true
        }

        if (-not $global:stateData.ContainsKey($ResourceID)) {
            return $true
        }

        if ($global:stateData[$ResourceID].State -ne $State) {
            return $true
        }

        $now = [datetime]::UtcNow
        $lastSent = [datetime]::Parse($global:stateData[$ResourceID].LastSent)
        if ($null -eq $lastSent -or ($now - $lastSent) -ge $Timespan) {
            return $true
        }

        return $false
    }

    if (Test-SendEvent -ResourceID $ResourceID -State $State -Timespan $Timespan) {
        # Write to state so that future function calls remember the last message of this resource
        $global:stateData[$ResourceID] = @{
            State = $State
            LastSent = [datetime]::UtcNow.ToString("o")
        }

        $monitoringParameters = @{
            Message        = $Message
            State          = $State
            ResourceID     = $ResourceID
            AffectedEntity = $AffectedEntity
            AffectedObject = $AffectedObject
            Threshold      = $Threshold
            Value          = $Value
        }
        Send-MonitoringEvent @monitoringParameters
    }
}

function Stop-QbyMonitoring {
    param()

    function Set-BlobContent {
        param (
            [Parameter(Mandatory=$true)]
            [string]$BlobUrl,
            
            [Parameter(Mandatory=$true)]
            [string]$Content
        )

        try {
            # Get an access token for Azure Storage using Managed Identity
            $token = (Get-AzAccessToken -ResourceUrl "https://storage.azure.com").Token

            # Call the blob storage REST API with the access token
            $headers = @{
                "Authorization" = "Bearer $token"
                "x-ms-version"  = "2025-01-05"  # Ensure compatibility with latest Storage API version
                "x-ms-blob-type"= "BlockBlob"
            }

            Invoke-WebRequest -URI $BlobUrl -Headers $headers -Method Put -Body $Content -ContentType "application/json; charset=utf-8" | Out-Null
        } catch {
            Write-Error "Failed to write blob: $_"
        }
    }

    Write-Host "Writing state ..."

    if ([string]::IsNullOrWhiteSpace($global:stateBlobURL)) {
        return
    }

    if ($null -eq $global:stateData) {
        return
    }

    $content = $global:stateData | ConvertTo-JSON -Depth 3
    Set-BlobContent -BlobURL $global:stateBlobURL -Content $content
}

Export-ModuleMember -Function Start-QbyMonitoring, Stop-QbyMonitoring, Send-MonitoringEvent, Send-TimedMonitoringEvent

