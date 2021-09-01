module EasyPatch
  module FlashHashPatch

    def self.included(base)
      base.include(ActionView::Helpers::TextHelper)
      base.include(InstanceMethods)

      base.class_eval do
        alias_method_chain :to_session_value, :easy_extensions
      end
    end

    module InstanceMethods
      def to_session_value_with_easy_extensions
        session_values = to_session_value_without_easy_extensions
        if !session_values.nil? && session_values.key?('flashes')
          session_values['flashes'].each do |key, value|
            session_values['flashes'][key] = truncate_html(value, 1000).html_safe
          end
        end
        session_values
      end
    end
  end
end
EasyExtensions::PatchManager.register_rails_patch 'ActionDispatch::Flash::FlashHash', 'EasyPatch::FlashHashPatch'
