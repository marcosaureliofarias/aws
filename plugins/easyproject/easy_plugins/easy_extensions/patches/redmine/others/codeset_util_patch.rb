module EasyPatch
  module CodesetUtilPatch

    def self.included(base)

      base.class_eval do
        const_set(:ENCODING_EXCEPTIONS, [Encoding::UndefinedConversionError, Encoding::ConverterNotFoundError, Encoding::CompatibilityError].freeze)

        class << self
          def safe_from_utf8(str, encoding)
            begin
              from_utf8(str.to_s, encoding)
            rescue
              str.to_s
            end
          end
        end

      end
    end

  end
end
EasyExtensions::PatchManager.register_other_patch 'Redmine::CodesetUtil', 'EasyPatch::CodesetUtilPatch'
