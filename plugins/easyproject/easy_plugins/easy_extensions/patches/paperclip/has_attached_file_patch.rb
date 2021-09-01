module EasyPatch
  module Paperclip
    module HasAttachedFilePatch

      def self.included(base)
        base.include(InstanceMethods)

        base.class_eval do

          alias_method_chain :define, :easy_extensions

          def add_easy_assets_callbacks
            @klass.send(:after_save, :copy_to_public)
            @klass.send(:after_destroy, :remove_from_public)
          end

          def define_easy_assets_callbacks_methods
            @klass.send(:define_method, 'copy_to_public') { EasyExtensions::EasyAssets.copy_to_public(self) }
            @klass.send(:define_method, 'remove_from_public') { EasyExtensions::EasyAssets.remove_from_public(self) }
          end

        end
      end

      module InstanceMethods
        def define_with_easy_extensions
          define_without_easy_extensions
          if EasyExtensions::EasyProjectSettings.enable_copying_easy_images_to_public
            define_easy_assets_callbacks_methods
            add_easy_assets_callbacks
          end
        end
      end

    end
  end

end

EasyExtensions::PatchManager.register_patch_to_be_first 'Paperclip::HasAttachedFile', 'EasyPatch::Paperclip::HasAttachedFilePatch'
