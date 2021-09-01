module EasyPatch
  module Paperclip
    module ThumbnailPatch

      def self.included(base)
        base.include(InstanceMethods)

        base.class_eval do

          alias_method_chain :make, :easy_extensions

        end
      end

      module InstanceMethods
        def make_with_easy_extensions
          src = @file
          dst = Tempfile.new([@basename, @format ? ".#{@format}" : File.extname(src.path)])
          dst.binmode
          format   = @format ? @format.to_s : src.path.split('.').last
          instance = @attachment.instance

          begin
            crop_attributes = { :crop => { :width => instance.crop_width.to_i, :height => instance.crop_height.to_i, :x => instance.crop_x.to_i, :y => instance.crop_y.to_i } } if instance.cropping?
            resize_method   = @convert_options.include?('-extent') ? :resize_image : :resize_image_to_fit
            EasyExtensions::ImageProcessing.send(resize_method, src.path, @target_geometry.width, @target_geometry.height, { :geometry => @target_geometry, :dst => dst.path, :format => format }.merge!(crop_attributes || {}))
          rescue EasyExtensions::ImageProcessing::AdapterProcessException => e
            raise ::Paperclip::Errors::NotIdentifiedByImageMagickError.new, e.message
          rescue EasyExtensions::ImageProcessing::MissingAdapterException
            FileUtils.cp(src.path, dst.path)
          end
          dst
        end

      end

    end
  end

end

EasyExtensions::PatchManager.register_patch_to_be_first 'Paperclip::Thumbnail', 'EasyPatch::Paperclip::ThumbnailPatch'
