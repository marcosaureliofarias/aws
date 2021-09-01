module EasyRedmine
  module EasyPatch
    module EasyAssetsControllerPatch

      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do

          alias_method_chain :file_path, :easy_redmine

        end
      end

      module InstanceMethods
        def file_path_with_easy_redmine
          if Redmine::Plugin.installed?(:easy_theme_designer) && EasyThemeDesign.in_use
            file_path_without_easy_redmine
          else
            File.join(Redmine::Plugin.find(:easy_redmine).assets_directory, '/stylesheets/typography.css')
          end
        end
      end

    end
  end
end
EasyExtensions::PatchManager.register_controller_patch 'EasyAssetsController', 'EasyRedmine::EasyPatch::EasyAssetsControllerPatch'
