module EasyPatch
  module Paperclip
    module MediaTypeSpoofDetectorPatch

      def self.included(base)
        base.include(InstanceMethods)

        base.class_eval do

          alias_method_chain :spoofed?, :easy_extensions

        end
      end

      module InstanceMethods
        def spoofed_with_easy_extensions?
          #::Paperclip.with_imagemagick? ? spoofed_without_easy_extensions? : false
          false
        end

      end

    end
  end

end

EasyExtensions::PatchManager.register_patch_to_be_first 'Paperclip::MediaTypeSpoofDetector', 'EasyPatch::Paperclip::MediaTypeSpoofDetectorPatch'
