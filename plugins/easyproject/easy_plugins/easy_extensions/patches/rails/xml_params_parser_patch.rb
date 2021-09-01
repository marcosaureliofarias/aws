# Rails Middleware
module EasyPatch
  module ActionDispatch
    module XmlParamsParserPatch

      def self.included(base)
        base.extend(ClassMethods)
        base.include(InstanceMethods)

        base.class_eval do
          alias_method_chain :parse_formatted_parameters, :easy_extensions
        end
      end

      module InstanceMethods

        # Microsoft office send binary XML but content type is text/xml
        def parse_formatted_parameters_with_easy_extensions(env)
          if env['PATH_INFO'].to_s.start_with?(*EasyExtensions.skip_middleware_xml_parser_for)
            nil
          else
            parse_formatted_parameters_without_easy_extensions(env)
          end
        end

      end

      module ClassMethods
      end

    end
  end
end
#EasyExtensions::PatchManager.register_rails_patch 'ActionDispatch::XmlParamsParser', 'EasyPatch::ActionDispatch::XmlParamsParserPatch'
