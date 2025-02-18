<#  
.SYNOPSIS  
Provides functions for sending monitoring events from Azure Functions to the q.beyond event pipeline,
including initialization and sending monitoring data to a specified service.

.DESCRIPTION  
This module includes two functions:

1. Initialize-Monitoring: Initializes monitoring settings, including description, name, package, and service URI. It also parses the script name and version to set monitoring-related global settings.
2. Send-MonitoringEvent: Sends a monitoring event (OK, CRITICAL or WARNING) with additional details.

These functions facilitate integration with external monitoring systems, allowing to log and report events from within Azure Functions.

.NOTES  
Author: Mauricé Ricardo Bärisch 
Date: 2025-02-18  
Version: 1.0  
#>

function Initialize-QbyMonitoring {
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
        [string]$ScriptVersion = $null
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
        Uri = $ServiceUri
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

    #Invoke-RestMethod -Method POST -Uri $global:QbyMonitoringSettings.ServiceUri -Body $jsonString -Headers $headers
    Write-Host $jsonString
}

Export-ModuleMember -Function Initialize-QbyMonitoring, Send-MonitoringEvent

