# Changelog



## [Unreleased]

## [1.4.17] - 2021-02-25
### Added
- redmine setting parent_issue_done_ratio

## [1.4.16] - 2020-02-01
### Added
- added comment requirment for time entries to issue type


## [1.4.15] - 2020-11-09
### Fixed
- Setting#date_format


## [1.4.14] - 2020-11-09
### Fixed
- IssueRelation#name improves


## [1.4.13] - 2020-09-04
### Added
- CustomValue#editable allow null


## [1.4.12] - 2020-09-04
### Added
- add EasyCurrency type


## [1.4.11] - 2020-08-24
### Added
- Issue#manage_subtasks


## [1.4.10] - 2020-05-21
### Added
- Issue#time_entries_custom_values takes argument activity_id


## [1.4.9] - 2020-05-18
### Added
- Issue#add_issues
- Issue#move_issues
- Issue#copy_issues


## [1.4.8] - 2020-05-18
### Added
- IssueRelation#relation_name


## [1.4.7] - 2020-04-07
### Added
- Redmine#start_of_week


## [1.4.6] - 2020-04-07

## [1.4.5] - 2020-04-02
### Added
- Activated plugins list
- Issue#deletable


## [1.4.4] - 2020-03-26
### Fixed
- User#enabled_attendance_status check if object is ::User


## [1.4.3] - 2020-03-26
### Fixed
- User#enabled_attendance_status check if plugin is enabled?


## [1.4.2] - 2020-03-10
### Added
- Enabled features -> rys issue_duration


## [1.4.1] - 2020-03-10
### Added
- TimeEntry#easy_is_billable
- EasySetting billable_things_default_state

### Changed
- Allow custom field description to be null


## [1.4.0] - 2020-02-14
### Added
- Custom field errors
- Extend mutation base


## [1.3.3] - 2020-01-30
### Added
- EasyGraphql::Types::Base::has_journals


## [1.3.2] - 2020-01-23
### Changed
- Change setting register

### Added
- Allowed settings
- Project ID for settings


## [1.3.1] - 2020-01-22
### Changed
- Freeze graphql to minor version ~> 1.10.0


## [1.3.0] - 2020-01-21
### Changed
- Freeze graphql version to 1.10

### Fixed
- Add third parameter to EasyGraphql::Fields::Base#authorized?


## [1.2.3] - 2020-01-16
### Added
- Enabled project features
- Billable feature


## [1.2.2] - 2020-01-15
### Changed
- Issue required_attribute_names contain custom_fields as well


## [1.2.1] - 2020-01-10
### 
###
###
###
###
###
###
###
###
###
###
###
###
###
###
###
###
- issue_private_note_as_default setting


## [1.2.0] - 2020-01-08
### Added
- Mutation - CustomValueChange
- More custom field attributes
- EasyGroupType
- CustomValue - editable, possible_values

### Changed
- CustomValue - value divided into value and formatted_value


## [1.1.29] - 2020-01-07
### Added
- Issue - private_notes_enabled
- Issue - set_is_private


## [1.1.28] - 2019-11-25
### Added
- issue_validate
- Error type
- Issue - safe attribute names
- Issue - required attribute names

### Changed
- issue validate new issue


## [1.1.27] - 2019-11-19
### Added
- Setting - time_format


## [1.1.26] - 2019-11-13
### Fixed
- Missing rack.input


## [1.1.25] - 2019-10-25
### Added
- Setting - date_format


## [1.1.24] - 2019-10-24
### Added
- Private journal field


## [1.1.23] - 2019-10-22
### Fixed
- easy_is_billable can be null


## [1.1.22] - 2019-10-16
### Fixed
- Missing user on journal_notes mutation


## [1.1.21] - 2019-10-15
### Added
- Journal mutation


## [1.1.20] - 2019-10-08
### Added
- Mark as read mutation


## [1.1.19] - 2019-10-04
### Added
- Journals order by user settings


## [1.1.18] - 2019-09-11
### Added
- all_issue_relation_types for Issue


## [1.1.17] - 2019-09-09
### Added
- all_available_parents, all_available_relations for Issue


## [1.1.16] - 2019-09-09
### Added
- attachment_max_size to settings


## [1.1.15] - 2019-09-05
### Fixed
- GraphQL patch


## [1.1.14] - 2019-09-03
### Added
- Enabled field to Tracker


## [1.1.13] - 2019-09-03
### Added
- Setting field


## [1.1.12] - 2019-08-30
### Added
AttachmentVersion type
AttachmentVersions to Attachment
version field to Attachment


## [1.1.10] - 2019-08-21
### Added
- Create new line


## [1.1.9] - 2019-08-21
### Added
- webdav url


## [1.1.8] - 2019-08-20
### Added
- attachment custom fields


## [1.1.7] - 2019-08-16
### Added
- issue spent time

### Fixed
- url textilizable


## [1.1.1] - 2019-06-11
### Fixed
- Tests are working without easy_extensions


## [1.1.0.beta] - 2019-06-02
### Added
- Loading graphql from redmine plugins

### Changed
- Files moved from app/graphql into app/api
