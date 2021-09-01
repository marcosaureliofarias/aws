module EasyPatch
  module Paperclip
    module HelpersPatch

      def self.included(base)
        base.class_eval do

          def with_imagemagick?
            return @with_imagemagick unless @with_imagemagick.nil?
            run('identify', '-version', {}, { :swallow_stderr => true })
            run('convert', '-version', {}, { :swallow_stderr => true })
            @with_imagemagick = true
          rescue Terrapin::ExitStatusError, Terrapin::CommandNotFoundError
            @with_imagemagick = false
          end
        end
      end
    end
  end

end

EasyExtensions::PatchManager.register_patch_to_be_first 'Paperclip::Helpers', 'EasyPatch::Paperclip::HelpersPatch'
