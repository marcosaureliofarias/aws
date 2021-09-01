Redmine::Plugin.register :ckeditor do
  visible false
  should_be_disabled false
  migration_order 100

  plugin_in_relative_subdirectory File.join('easyproject', 'easy_helpers')
end
