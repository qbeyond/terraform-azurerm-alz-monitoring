# MSSQL Monitoring

A PowerShell script that monitors Azure MSSQL databases by trying
to connect to them via a connection string. This connection string
may contain SQL-based authentication, if not, EntraID authentication
is used, meaning that the managed identity of the Monitoring Function
App needs permissions on that particular database.

## Requirements

- Managed Identity of the Function App needs read permissions on alz scope
- Managed Identity of the Function App needs permissions on databases
where EntraID authentication is used
- Function App needs to be integrated into a vNet for private DBs being monitored
- The integrated vNet must resolve DNS requests to monitored DBs to their private IPs
- Function App needs public internet access to send monitoring data to the event pipeline
