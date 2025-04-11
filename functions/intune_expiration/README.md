# Intune Expiration

A simle monitoring script that checks whether intune certificates are about to expire.

## Required env variables (set via `var.functions_config.env_vars`)
- `$env:endpoints` - for example "['applePushNotificationCertificate',   'vppTokens',   'depOnboardingSettings']"

## Required Permissions
The managed identity of the function app needs to have the following Event Graph permissions:
`DeviceManagementConfiguration.Read.All`.

Requirements:
- an account with global admin permissions in Azure Actuve Directory/EntraID
- the PowerShell module `AzureAD` being installed

Properly set the $TenantID and $DisplayNameOfMSI (the function app name)
and execute the following PowerShell script:

```powershell
$TenantID = "00000000-0000-0000-0000-000000000000"
$GraphAppId = "00000003-0000-0000-c000-000000000000"
$DisplayNameOfMSI = "func-<stage>-Monitoring-<cust>-01"
$PermissionName = "DeviceManagementConfig.Read.All"

Connect-AzureAD -TenantId $TenantID

$MSI = (Get-AzureADServicePrincipal -Filter "displayName eq '$DisplayNameOfMSI'")

Start-Sleep -Seconds 10

$GraphServicePrincipal = Get-AzureADServicePrincipal -Filter "appId eq '$GraphAppId'"

$AppRole = $GraphServicePrincipal.AppRoles | Where-Object {$_.Value -eq $PermissionName -and $_.AllowedMemberTypes -contains "Application"}

New-AzureAdServiceAppRoleAssignment -ObjectId $MSI.ObjectId -PrincipalId $MSI.ObjectId -ResourceId $GraphServicePrincipal.ObjectId -Id $AppRole.Id
```powershell
