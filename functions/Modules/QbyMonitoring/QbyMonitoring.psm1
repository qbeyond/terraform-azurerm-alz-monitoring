<#

#>

function Initialize-Monitoring {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Description,
        [Parameter(Mandatory=$true)]
        [string]$Name,
        [Parameter(Mandatory=$true)]
        [string]$Package,
        [string]$ScriptName = (Get-Item $PSCommandPath).BaseName,
        [string]$ScriptVersion
    )

    $global:QbyMonitoringSettings = @{
        schemaId = 'FunctionApp'

    }
}

function Send-MonitoringEvent {
    param(
        [string]$Message,
        [string]$Severity
    )    

    $body = @{
        fields = @{
            TimeGenerated = Get-Date -Format "dd-MM-yyy HH:mm"
            _ResourceID = "/SUBSCRIPTIONS/test/RESOURCEGROUPS/INTUNE/PROVIDERS/INTUNE.MICROSOFT.DEVICEMANAGEMENT/APPLEIDENTIFIER/test"
            additional_information = "The certificate for will expire at . The certificate needs to be renewed."
            affected_entity = "appleIdentifier"
            affected_object = "Intune"
            monitor_description = "Monitors"
            monitor_name = "AZ"
            monitor_package = "Config"
            script_name = "n/a"
            script_version = "n/a"
            state = "warning"
            threshold = "warningThresholdInDays"
            value = "expirationDateTime"
        }
        schemaId = "FunctionApp"
    }

    $jsonString = $body | ConvertTo-Json -Depth 3

    $headers = @{
        "Content-Type" = "application/json"
    }
    Invoke-RestMethod -Method POST -Uri $uri -Body $jsonString -Headers $headers
}

Export-ModuleMember -Function Initialize-Monitoring, Send-MonitoringEvent
