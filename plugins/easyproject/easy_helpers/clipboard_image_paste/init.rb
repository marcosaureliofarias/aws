#*******************************************************************************
# clipboard_image_paste Redmine plugin.
#
# Authors:
# - Richard Pecl
#
# Terms of use:
# - GNU GENERAL PUBLIC LICENSE Version 2
#*******************************************************************************

Redmine::Plugin.register :clipboard_image_paste do
  name        'Clipboard image paste'
  author      'Richard Pecl'
  description 'Paste cropped image from clipboard as attachment'
  url         'http://www.redmine.org/plugins/clipboard_image_paste'
  version     '1.9'
  requires_redmine :version_or_higher => '1.4.0'

  visible false
  migration_order 100
  should_be_disabled false
  plugin_in_relative_subdirectory File.join('easyproject', 'easy_helpers')

  configfile = File.join(File.dirname(__FILE__), 'config', 'settings.yml')
  $clipboard_image_paste_config = YAML::load_file(configfile)

  $clipboard_image_paste_has_jquery = true
end
