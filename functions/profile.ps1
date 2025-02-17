# Import required Az and Microsoft Graph modules
$modules = @(
    'Az.Accounts',
    'Az.ResourceGraph',
    'Az.KeyVault',
    'Microsoft.Graph',
    'Microsoft.Graph.Identity.Governance'
)

foreach ($module in $modules) {
    try {
        Import-Module $module -ErrorAction Stop
        Write-Host "Successfully imported module: $module"
    } catch {
        Write-Host "Failed to import module: $module - $_"
    }
}
