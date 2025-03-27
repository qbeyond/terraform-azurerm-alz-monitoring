# Intune Expiration

A simle monitoring script that checks whether intune certificates are about to expire.

## Required env variables (set via `var.functions_config.env_vars`)
- `$env:endpoints` - for example "['applePushNotificationCertificate',   'vppTokens',   'depOnboardingSettings']"
