# Monitoring Functions

This module deploys a function app for monitoring scripts, if at least one function
in `var.functions_config.stages` is not set to off and `var.event_pipeline_config.enabled`
is set to true.

## Vnet Integration

The function app can be integrated into a vnet by passing a subnet greater or equal than
`/26` to `var.functions_config.subnet_id`. This subnet must be dedicated to the function app,
as it requires setting a service delegation for `Microsoft.Web/serverFarms` as shown below:

```terraform
resource "azurerm_subnet" "func_subnet" {
  name                 = "snet-10-1-0-0-24-MonitoringFunctionApp"
  virtual_network_name = azurerm_virtual_network.test_vnet2.name
  resource_group_name  = azurerm_resource_group.test_sql.name
  address_prefixes     = ["10.0.2.128/26"]

  delegation {
    name = "functionapp-delegation"

    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}
```

## How to add a function

You want to add a monitoring script to this function app? Follow these steps:

### Put the function code into `/functions`

Write the function and put it into `functions/<func>/`. The directory should contain

- `run.ps1`: the file containing the monitoring script
- `function.json`: defines triggers and input/outputs for the monitoring function,
e.g. a time trigger every 5min:
```json
{
  "bindings": [
    {
      "name": "Timer",
      "type": "timerTrigger",
      "direction": "in",
      "schedule": "0 */5 * * * *"
    }
  ]
}
```
- `README.md`: please describe what the function does and how it operates

### Register the function in the terraform code

1. In `variables.tf`, update the type `functions_config.stages` 
and its description to include your new <func>
2. In `locals.tf`, add <func> to the list `all_functions`

### Verify PowerShell dependencies

Go to [requirements.psd1] (../functions/requirements.psd1) and make sure that it contains
all the modules needed for your function. Add missing dependencies here, as they will be
automatically loaded when the Azure Function App initializes by `profile.ps1`.

## Environment variables

By default, each function deployed by this module's function app has access to the following
environment variables:
- `<func>_SERVICE_URI`: The service uri used by this function, either the productive or the integration pipeline
- `<func>_STATE_URL`: A url to the JSON state blob used by `Send-TimedMonitoringEvent`

## QBY Monitoring

Along with the monitoring scripts code, a common module is deployed:
[QbyMonitoring] (../functions/Modules/QbyMonitoring/QbyMonitoring.psm1).
This module may be used to send Monitoring Events directly to the event pipeline.

Here is an example:

```powershell
$MonitoringParameters = @{
    Package = "MSSQL Monitor"
    Description = "This script regularly checks MSSQL databases for availability"
    Name = "MSSQL Monitor"
    ScriptName = "sql_monitor"
    ScriptVersion = "1.0"
    ServiceUri = $env:SQL_SERVICE_URI
    BlobURL = $env:SQL_STATE_URL
}
Start-QbyMonitoring @MonitoringParameters

Send-MonitoringEvent -Message "Test event" -State "OK" -ResourceID "n/a"`
    -AffectedEntity "n/a" -AffectedObject = "n/a"

# Only sends monitoring event if state differs or timespan has passed
# Relies on Start-QbyMonitoring to read and Stop-QbyMonitoring to write
# the function's state data to the storage blob `$env:SQL_STATE_URL`
Send-TimedMonitoringEvent -Message "Error event" -State "CRITICAL" -ResourceID "n/a"`
    -AffectedEntity "n/a" -AffectedObject = "n/a" -Timespan "00:30:00"

Stop-QbyMonitoring
```
