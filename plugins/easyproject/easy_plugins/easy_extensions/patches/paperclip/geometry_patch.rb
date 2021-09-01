module EasyPatch
  module Paperclip
    module GeometryPatch

      def self.included(base)
        base.extend(ClassMethods)

        base.class_eval do

          class << self
            alias_method_chain :from_file, :easy_extensions
          end

        end
      end

      module ClassMethods
        def from_file_with_easy_extensions(file)
          file_path = file.path if file.respond_to?(:path)
          EasyExtensions::ImageProcessing.get_geometry(file_path || file) || raise(EasyExtensions::ImageProcessing::AdapterProcessException.new)
        rescue EasyExtensions::ImageProcessing::AdapterProcessException
          ::Paperclip::Geometry.new
        rescue EasyExtensions::ImageProcessing::MissingAdapterException
          ::Paperclip::Geometry.new
        end
      end
    end
  end

end

EasyExtensions::PatchManager.register_patch_to_be_first 'Paperclip::Geometry', 'EasyPatch::Paperclip::GeometryPatch'
