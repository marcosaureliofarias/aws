module EasyRedmine
  module EasyPatch
    module EasyErrorsHelperPatch

      def self.included(base)
        base.include(InstanceMethods)
        base.class_eval do
          alias_method_chain :error_stylesheet_path, :easy_redmine
        end
      end

      module InstanceMethods
        def error_stylesheet_path_with_easy_redmine
          if EasySetting.value('ui_theme').present?
            Pathname.new('/plugin_assets/easy_redmine/stylesheets/easy_redmine')
          else
            error_stylesheet_path_without_easy_redmine
          end
        end
      end
    end
  end
end
RedmineExtensions::PatchManager.register_helper_patch 'EasyErrorsHelper', 'EasyRedmine::EasyPatch::EasyErrorsHelperPatch'
