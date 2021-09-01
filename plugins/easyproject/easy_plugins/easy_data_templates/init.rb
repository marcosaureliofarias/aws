require 'redmine'

unless Object.const_defined?(:EASY_EXTENSIONS_ENABLED)
  if Object.const_defined?(:EasyExtensions)
    EASY_EXTENSIONS_ENABLED = true
  else
    EASY_EXTENSIONS_ENABLED = false
  end
end

Redmine::Plugin.register :easy_data_templates do
  name(EASY_EXTENSIONS_ENABLED ? :easy_data_templates_plugin_name : 'Easy Data Templates')
  author(EASY_EXTENSIONS_ENABLED ? :easy_data_templates_plugin_author : 'Easy Software')
  author_url(EASY_EXTENSIONS_ENABLED ? :easy_data_templates_plugin_author_url : 'http://www.easyredmine.com')
  description(EASY_EXTENSIONS_ENABLED ? :easy_data_templates_plugin_description : '- MS Project import, ...')
  version '2019'
  visible(false)  if EASY_EXTENSIONS_ENABLED
  migration_order(300) if EASY_EXTENSIONS_ENABLED
  requires_redmine_plugin(:easy_extensions, version_or_higher: '2019') if EASY_EXTENSIONS_ENABLED
  plugin_in_relative_subdirectory(File.join('easyproject', 'easy_plugins')) if EASY_EXTENSIONS_ENABLED
end

unless EASY_EXTENSIONS_ENABLED
  require File.dirname(__FILE__) + '/after_init'
end
