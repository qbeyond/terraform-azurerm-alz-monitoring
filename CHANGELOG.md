# Changelog

All notable changes to this module will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this module adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [6.8.1] - 2026-02-04

### Fixed

- Fixed managed identity validation 

## [6.8.0] - 2026-02-04

### Added

- Added managed identity support for additional query alert rules, with validation for SystemAssigned and UserAssigned identities.

## [6.7.0] - 2026-01-19

### Added

- Added optional variables enabled, severity, skip_query_validation and target_resource_types to the resource azurerm_monitor_scheduled_query_rules_alert_v2
- Added optional variables to the documentation
- Added a feature for editing values of the default_querries by writing them into the addtional_querries block
- Added the new feature to the example extra_querries

## [6.6.0] - 2025-12-08

### Added

- Added optional consumption logic app that parses metric alerts into qbeyond alert schema for further investigation.
- Added optional action group that sends alert to logic app.

## [6.5.2] - 2025-10-27

### Fixed

- Fixed error calling URI in azurerm_automation_module az_accounts due to retired URI (https://learn.microsoft.com/en-us/powershell/gallery/how-to/getting-support/troubleshooting-cmdlets?view=powershellget-3.x#required-network-endpoints)

## [6.5.1] - 2025-09-25

### Fixed

- Fixed failing periods validation when there was no failing period defined.

## [6.5.0] - 2025-09-19

### Added

- Additional Data Collection Rules (DCRs) via additional_data_collection_rules
- Input validations

## [6.4.0] - 2025-09-01

### Added

- Optional parameters in additional_queries variable.

## [6.3.1] - 2025-09-01

### Changed

- Backup alert rule now runs every hour instead of every two days

## [6.3.0] - 2025-07-29

### Added

- Alert rule for monitoring the availability of Azure SQL Databases
- Alert rule that triggers when availability metrics are no longer received

## [6.2.0] - 2025-06-20

### Added

- Made the customer code an optional parameter so that a service URI is not strictly required

### Fixed

- Spelling mistake for DCR category

## [6.1.0] - 2025-05-16

### Added

- Added more syslog data collection

## [6.0.1] - 2025-2-11

### Changed

- Fix version constraint `~>1.14.0` -> `~>1.14`

## [6.0.0] - 2025-1-27

### Added

- Feature/event query template by @qby-chhol in #27

## [5.4.1] - 2024-11-20

### Changed

- Fix backup kusto query

## [5.4.0] - 2024-11-15

### Changed

- Upgraded Az.Accounts Powershell version 50 3.0.5
  
## [5.3.0] - 2024-11-06

### Added

- Added option to include template variables in queries

### Changed

- Changed VM Backup query to generic Backup query

## [5.2.0] - 2024-09-30

### Added

- Added tags variable in somes resources

## [5.1.0] - 2024-08-20

### Added

- Custom log monitoring

## [5.0.0] - 2024-04-04

### Added

- DCRs for security monitoring

### Changed

- Switched alert rules to alert rules v2

## [4.2.1] - 2024-06-11

### Fixed

- Fixed Resource-Graph query so tag filtering properly excludes Arc machines

## [4.2.0] - 2024-04-04

### Added

- ouput of `action_group_id`
- Apply all examples on `terraform test`

## [4.1.0] - 2024-03-27

### Added

- Added Tags as variable

## [4.0.0] - 2024-03-15

### Added

- DCRs for VM-Insights and Event-Log

### Changed

- Updated Kusto queries for new AMA

### Removed

- Legacy datasources and VM-Insights solution

## [3.2.0] - 2024-01-31

### Added

- Override paremter to allow for different management groups

## [3.1.0] - 2024-01-12

### Added

- New alert rule for failed VM backup jobs

### Changed

- Naming of existing rules
- Schedule of Resource Graph query to twice daily as intended

### Removed

### Fixed

## [3.0.0] - 2024-01-02

### Added

- New example for new feature

### Changed

- Put all action group configuration into one variable
- Made the webhook configuration optional

### Removed

### Fixed

- Removed unused parameter for secret

## [2.0.3] - 2023-12-07

### Added

### Changed

### Removed

### Fixed

- Parameters disappearing from the job schedule on updates of the runbook

## [2.0.2] - 2023-08-08

### Added

- Changelog

### Changed

### Removed

- No longer existing parameters in examples

### Fixed

## [5.1.0] - 2024-08-08

### Added

- new LAW Tables for Custom Text logs
- new LAW Tables for Custom JSON logs
- Custom Text Log Data Collection Rule
- Custom JSON Log Data Collection Rule
- Alert rule with action group for incomming custom JSON logs
- Alert rule with action group for incomming custom text logs
- Add Data Collection Endpoint based on optional additional regions
- Add non_productive attribute to alert rules
- Add integration service uri and event pipeline

### Changed

### Removed

### Fixed

## [6.0.0] - 2025-01-15

### Added

- generic windows event kusto query terraform template
- optional event alert rule
- services the alert rules should be attributed to (extend monitor_package)

### Changed

- non_productive attribute in alert rules default set to false

### Removed

- windows event ID 6008 kusto query
- windows event ID 55 kusto query
- windows event ID 6008 EventLog alert rule
- windows event ID 55 EventLog alert rule

### Fixed

- example extra_queries functionality
