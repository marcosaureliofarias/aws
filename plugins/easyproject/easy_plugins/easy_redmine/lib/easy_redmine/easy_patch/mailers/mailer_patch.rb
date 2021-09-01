module EasyRedmine
  module EasyPatch
    module MailerPatch

      def self.included(base)
        base.extend ClassMethods
        base.include InstanceMethods

        base.class_eval do
          class << self

            alias_method_chain :inline_css_file_path, :easy_redmine

          end
        end
      end

      module InstanceMethods
      end

      module ClassMethods
        def non_inline_css_file_path_with_easy_redmine
          if !EasySetting.value(:ui_theme) || (Redmine::Plugin.installed?(:easy_theme_designer) && EasyThemeDesign.in_use_globally)
            non_inline_css_file_path_without_easy_redmine
          else
            assets_path = Redmine::Plugin.find(:easy_redmine).assets_directory
            File.join(assets_path, 'stylesheets', 'mailer', '_mailer_non_inline.css')
          end
        end

        def inline_css_file_path_with_easy_redmine
          if !EasySetting.value(:ui_theme) || (Redmine::Plugin.installed?(:easy_theme_designer) && EasyThemeDesign.in_use_globally)
            inline_css_file_path_without_easy_redmine
          else
            assets_path = Redmine::Plugin.find(:easy_redmine).assets_directory
            File.join(assets_path, 'stylesheets', 'mailer', '_mailer_inline.css')
          end
        end
      end

    end
  end
end
EasyExtensions::PatchManager.register_model_patch 'Mailer', 'EasyRedmine::EasyPatch::MailerPatch'
