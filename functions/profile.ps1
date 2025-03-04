# Path to the requirements.psd1 file (assuming it's in the same directory as profile.ps1)
$requirementsPath = Join-Path $PSScriptRoot "requirements.psd1"

# Read and parse the requirements.psd1 file
if (Test-Path $requirementsPath) {
    try {
        $moduleRequirements = Invoke-Expression -Command (Get-Content $requirementsPath -Raw)

        # Extract module names from the hashtable
        $modules = $moduleRequirements.Keys

        # Import each module
        foreach ($module in $modules) {
            try {
                Import-Module $module -ErrorAction Stop
                Write-Host "Successfully imported module: $module"
            } catch {
                Write-Host "Failed to import module: $module - $_"
            }
        }
    } catch {
        Write-Host "Failed to parse requirements.psd1: $_"
    }
} else {
    Write-Host "requirements.psd1 not found! Skipping module import."
}

# Authenticate using the managed identity
Connect-AzAccount -Identity
