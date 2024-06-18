# Changelog
All notable changes to this module will be documented in this file.
 
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this module adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased] - yyyy-mm-dd

### Added
- DCRs for security monitoring

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
=======
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
