module EasyRedmine
  module EasyPatch
    module EasyThemeDesignerPatch

      def self.included(base)
        base.extend(ClassMethods)
        base.class_eval do

          class << self

            alias_method_chain :theme_template_files, :easy_redmine
            alias_method_chain :theme_source_variables_file, :easy_redmine

          end

        end
      end

      module ClassMethods

        def theme_template_files_with_easy_redmine
          files = theme_template_files_without_easy_redmine
          files['theme'] = File.join(Redmine::Plugin.find('easy_redmine').directory, 'assets', 'stylesheets', 'easy_theme_designer', 'theme.scss.erb')
          files
        end

        def theme_source_variables_file_with_easy_redmine
          File.join(Redmine::Plugin.find('easy_redmine').directory, 'assets', 'stylesheets', 'easy_redmine', '_variables_primary.scss')
        end

      end
    end
  end
end
RedmineExtensions::PatchManager.register_helper_patch 'EasyThemeDesigner', 'EasyRedmine::EasyPatch::EasyThemeDesignerPatch', if: proc { Redmine::Plugin.installed?(:easy_theme_designer) }
