<#  
.SYNOPSIS  
Provides functions for sending monitoring events from Azure Functions to the q.beyond event pipeline,
including initialization and sending monitoring data to a specified service.

.DESCRIPTION  
This module includes two functions:

1. Start-QbyMonitoring: Initializes monitoring settings, including description, name, package, and service URI. It also parses the script name and version to set monitoring-related global settings.
2. Send-MonitoringEvent: Sends a monitoring event (OK, CRITICAL or WARNING) with additional details.
3. Send-TimedMonitoringEvent: Sends a monitoring event only if the state of the resource id has changed or a certain timespan has elapsed.

These functions facilitate integration with external monitoring systems, allowing to log and report events from within Azure Functions.

.NOTES  
Author: Mauricé Ricardo Bärisch 
Date: 2025-03-11
Version: 1.0  
#>

function Start-QbyMonitoring {
    <#
    .SYNOPSIS  
    Initializes monitoring settings for a script.

    .DESCRIPTION  
    This function sets up the global monitoring settings, including description, name, package, and service URI.
    If the script name and version are not provided, the script name is inferred from the script's filename, and the version is extracted from the script name.
    Also downloads the state of previous runs from mounted Azure File Share.

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

    .PARAMETER Timespan
    The default timespan that should elapse until `Send-TimedMonitoringEvent` sends a new monitoring event of the same state.

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

        # Optional, sets a default timespan for Send-TimedMonitoringEvent
        [timespan]$Timespan = "01:00:00"
    )

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
        ServiceUri = $ServiceUri
        Timespan = $Timespan
    }

    $global:stateData = @{}

    try {
        $stateObject = Get-Content -Path "/mounts/states/$($ScriptName).json" -ErrorAction Stop | ConvertFrom-JSON

        # Turn PSCustomObject into hashtable
        $stateObject.PSObject.Properties | ForEach-Object {
            $global:stateData[$_.Name] = $_.Value
        }
    } catch {
        Write-Host "No state file found."
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

    $headers = @{"Content-Type" = "application/json"}

    Invoke-RestMethod -Method POST -Uri $global:QbyMonitoringSettings.ServiceUri -Body $jsonString -Headers $headers
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

    .PARAMETER Timespan
    The timespan that should elapse until a new monitoring event of the same state should be sent.

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
        [timespan]$Timespan = $global:QbyMonitoringSettings.Timespan
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
    <#
    .SYNOPSIS
    Stops the Qby monitoring process and saves the current state to an Azure Blob Storage.

    .DESCRIPTION
    This function writes the monitoring state to an Azure File Share.

    .PARAMETERS
    None

    .NOTES
    - Requires Azure Accounts PowerShell module (`Az.Accounts`).
    - Uses Managed Identity to obtain an access token for Azure Storage.
    - Ensures data integrity by converting state data to JSON before uploading.
    #>
    param()
    
    Write-Host "Writing state ..."

    if ($null -eq $global:stateData) {
        Write-Warning "No state data found. Skipping state write."
        return
    }

    $content = $global:stateData | ConvertTo-JSON -Depth 3
    Set-Content -Path "/mounts/states/$($global:QbyMonitoringSettings.ScriptName).json" -Value $content
}

Export-ModuleMember -Function Start-QbyMonitoring, Stop-QbyMonitoring, Send-MonitoringEvent, Send-TimedMonitoringEvent
