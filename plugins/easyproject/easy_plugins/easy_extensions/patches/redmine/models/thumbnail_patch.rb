module EasyPatch
  module ThumbnailPatch

    def self.included(base)
      base.extend ClassMethods

      base.class_eval do
        class << self
          alias_method_chain :generate, :easy_extensions
          alias_method_chain :convert_available?, :easy_extensions
        end

      end
    end

    module ClassMethods

      def generate_with_easy_extensions(source, target, size, is_pdf = false)
        return nil if is_pdf && !gs_available?
        unless File.exists?(target)
          mime_type = File.open(source) {|f| MimeMagic.by_magic(f).try(:type) }
          return nil if !mime_type || (is_pdf && mime_type != "application/pdf")
          directory = File.dirname(target)
          unless File.exists?(directory)
            FileUtils.mkdir_p directory
          end
          if is_pdf
            size_option = "#{size}x#{size}>"
            cmd = "#{shell_quote CONVERT_BIN} #{shell_quote "#{source}[0]"} -thumbnail #{shell_quote size_option} #{shell_quote "png:#{target}"}"
            unless system(cmd)
              logger.error("Creating thumbnail failed (#{$?}):\nCommand: #{cmd}")
              return nil
            end
          elsif ::Paperclip.with_imagemagick?
            EasyExtensions::ImageProcessing.resize_image_to_fit(source, size, size, { :dst => target, :format => 'JPG', :geometry => "#{size}>x#{size}>" })
          end
        end
        File.exists?(target) ? target : source
      rescue EasyExtensions::ImageProcessing::MissingAdapterException
        source
      end

      def convert_available_with_easy_extensions?
        true
      end

    end
  end
end
EasyExtensions::PatchManager.register_model_patch 'Redmine::Thumbnail', 'EasyPatch::ThumbnailPatch'
