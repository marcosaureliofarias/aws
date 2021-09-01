require File.join(Rails.root, 'plugins', 'easyproject', 'easy_plugins', 'easy_extensions', 'lib', 'easy_extensions', 'tests', 'easy_test_prepare')

require 'easy_extensions/tests/rspec_json_formatter_patch'

EasyExtensions::Tests::EasyTestPrepare.to_prepare('easy_extensions') do

  directory File.dirname(__FILE__)

  redmine_settings['ui_theme']                             = 'easy_widescreen'
  redmine_settings['force_default_language_for_anonymous'] = '1'

  persist_table_fixtures([:easy_pages, :easy_page_templates, :easy_page_modules, :easy_page_zones, :easy_page_available_zones, :easy_page_available_modules])

  default_fixtures([:easy_user_time_calendars, :easy_attendance_activities, :easy_user_types])

  easy_settings_from_yml(YAML.load_file("#{Rails.root}/plugins/easyproject/easy_plugins/easy_extensions/config/easy_settings.yml"))

end
