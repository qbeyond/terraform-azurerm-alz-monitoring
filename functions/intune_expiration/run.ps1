#Prerequirements:
#Install-Module -Name Az -AllowClobber -Scope CurrentUser
#Import-Module -Name Az

#Required env variables
# $env:tenant_id - Azure ID of the current tenant
# $env:endpoints - for example "['applePushNotificationCertificate',   'vppTokens',   'depOnboardingSettings']"
# $env:INTUNE_EXPIRATION_SERVICE_URI - event uri

#Required env variables for alternative auth
# $env:secure_token
# $env:app_id

param($Timer)

#Check that required env variables are not null or empty
$requiredEnvVariables = @(
    "tenant_id",
    "endpoints"
)

foreach ($variable in $requiredEnvVariables) {
  if ([string]::IsNullOrEmpty((Get-Item "env:$variable").Value)) {
    Write-Error "env:$variable is not set. Exiting script."
    exit 1
  }
}

#Alternative auth
#$SecureStringPwd = $env:secure_token | ConvertTo-SecureString -AsPlainText -Force
#$pscredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $env:app_id, $SecureStringPwd
#Connect-AzAccount -ServicePrincipal -Credential $pscredential -Tenant $env:tenant_id

Connect-AzAccount -Identity

#$env:endpoints must contain list of endoints like "['applePushNotificationCertificate',   'vppTokens',   'depOnboardingSettings']"
$endpoints = $env:endpoints | ConvertFrom-Json

# Initialize thresholds
$warning_treshold_in_days = 30
$critical_treshold_in_days = 10

function Send-JSON {
  param (
      [string]$expiration_datetime,
      [string]$additional_information,
      [string]$identifier,
      [string]$warning_level,
      [string]$exceeded_treshold
  )

  # Define the nested hashtable
  $body = @{
    fields = @{
      TimeGenerated = Get-Date -Format "dd-MM-yyy HH:mm:ss"
      _ResourceID = "/SUBSCRIPTIONS/$env:tenant_id/RESOURCEGROUPS/INTUNE/PROVIDERS/INTUNE.MICROSOFT.DEVICEMANAGEMENT/APPLEIDENTIFIER"
      additional_information = "$additional_information"
      affected_entity = "$identifier"
      affected_object = "Intune"
      monitor_description = "Monitors the Intune Apple certificates & tokens."
      monitor_name = "AZ_INTUNE_CERTIFICATES_TOKEN"
      monitor_package = "ConfigItem_SC_ManagedCMMDPlatform"
      script_name = "n/a"
      script_version = "n/a"
      state = "$warning_level"
      threshold = "$exceeded_treshold"
      value = "$expiration_datetime"
    }
    schemaId = "FunctionApp"
  }

  # Convert the hashtable to a JSON string
  $json_string = $body | ConvertTo-Json -Depth 3
  # Output the JSON string
  Write-Output $json_string
  #$uri = "https://import-azure-alerts.azurewebsites.net/api/GenericWebhookJS1?code=$env:webhook_tenant_code&ClientId=$env:webhook_tenant_clientid"
  $uri = $env:INTUNE_EXPIRATION_SERVICE_URI
  $headers = @{
    "Content-Type" = "application/json"
    }
      Invoke-RestMethod -Method POST -Uri $uri -Body $json_string -Headers $headers
      Write-Output "fired to " $uri
}



foreach ($endpoint in $endpoints) {
  $result = Invoke-AzRestMethod "https://graph.microsoft.com/v1.0/deviceManagement/$endpoint"

  if ($result.StatusCode -ne 200){
    $status_code = $result.StatusCode
    $warning_level =  "error"
    
    $error_content = $result.Content | ConvertFrom-Json
    $error_content = $error_content.error
    Write-Error $result.Content
    $additional_information = "$endpoint endpoint is not reachable. It fails with code $status_code and message: {0}" -f $error_content.message
    $current_date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Send-JSON -expiration_datetime $current_date -additional_information $additional_information -identifier $endpoint -warning_level $warning_level -exceeded_treshold $warning_treshold_in_days
  } 
  elseif ($endpoint -eq "applePushNotificationCertificate"){
    $result_content = $result.Content | ConvertFrom-Json | Select-Object id,expirationDateTime,appleIdentifier,certificateSerialNumber
    } 
  elseif ($endpoint -eq "vppTokens") {
    $result_content = $result.Content | ConvertFrom-Json | Select-Object id,expirationDateTime,appleId,displayName
    } 
  elseif ($endpoint -eq "depOnboardingSettings"){
    $result_content = $result.Content | ConvertFrom-Json | Select-Object id,tokenExpirationDateTime,appleIdentifier
    }



  If (-Not([string]::IsNullOrEmpty($result_content))) {
    ForEach($raw_result in $result_content) {
      $raw_result.expirationDateTime ? ($expiration_datetime = $raw_result.expirationDateTime) : ($expiration_datetime = $raw_result.tokenExpirationDateTime)

      if ($expiration_datetime -lt (Get-Date).AddDays($warning_treshold_in_days)) {
        if  ($expiration_datetime -lt (Get-Date).AddDays($critical_treshold_in_days)){
          $warning_level =  "critical"
          $exceeded_treshold = $critical_treshold_in_days
        } 
        else {
          $warning_level =  "warning"
          $exceeded_treshold = $warning_treshold_in_days
        }
        $raw_result.appleIdentifier ? ($identifier = $raw_result.appleIdentifier) : ($identifier = $raw_result.appleId)
        $additional_information = "The $endpoint certificate will expire at $expiration_datetime for the Apple ID $identifier. The certificate needs to be renewed."

        Send-JSON -expiration_datetime $expiration_datetime -additional_information $additional_information -identifier $identifier -warning_level $warning_level -exceeded_treshold $warning_treshold_in_days
      }
    }
  } 
}
