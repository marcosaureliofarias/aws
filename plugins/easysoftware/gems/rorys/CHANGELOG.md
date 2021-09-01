# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
### Changed
- \#386341 if client have redis installed, but not configured, Rorys failed

## [1.2.3] - 2020-08-21
### Fixed
- everything delete all jobs, even rake or console => revert previous change


## [1.2.2] - 2020-08-13
### Fixed
- if redis is not installed or configured skip destroy cron jobs


## [1.2.1] - 2020-08-13
### Fixed
- condition for `queuing_environment?` return true even if adapter is not set to `sidekiq`

### Changed
- Destroy all cron jobs every-time - no-matter of adapter


## [1.2.0] - 2020-07-28
### Changed
- Use `EasyActiveJob` as a base class for Rorys::Task


## [1.1.2] - 2020-05-29
### Added
- log_info in rake task of Rorys

### Changed
- `sidekiq_available?` based on used queue adapter for active_job


## [1.1.1] - 2020-04-02
### Fixed
- rake_task name
- fix failures


## [1.1.0] - 2020-03-05
### Added
- switch for disable EasyRakeTask executing

### Fixed
- indent under private


## [1.0.1] - 2020-02-28

## [1.0.0] - 2020-01-27
### Added
- Init
