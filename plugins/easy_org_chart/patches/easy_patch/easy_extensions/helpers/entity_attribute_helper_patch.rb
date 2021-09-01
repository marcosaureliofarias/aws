module EasyOrgChart
  module EntityAttributeHelperPatch
    def self.included(base)
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      base.class_eval do
        alias_method_chain :format_html_user_attribute, :easy_org_chart
      end
    end

    module InstanceMethods
      def format_html_user_attribute_with_easy_org_chart(entity_class, attribute, unformatted_value, options={})
        if attribute.name == :supervisor

          if unformatted_value.present?
            if options[:no_link]
              h(unformatted_value.name)
            else
              link_to(unformatted_value.name, user_path(unformatted_value))
            end
          end

        else
          format_html_user_attribute_without_easy_org_chart(entity_class, attribute, unformatted_value, options)
        end
      end
    end

    module ClassMethods

    end
  end
end

RedmineExtensions::PatchManager.register_helper_patch 'EntityAttributeHelper', 'EasyOrgChart::EntityAttributeHelperPatch'
