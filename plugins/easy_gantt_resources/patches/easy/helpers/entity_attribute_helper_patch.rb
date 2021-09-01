module EasyGanttResources
  module EntityAttributeHelperPatch

    def self.included(base)
      base.class_eval do
        alias_method_chain :format_issue_attribute, :easy_gantt_resources

        def format_easy_gantt_resource_attribute(entity_class, attribute, unformatted_value, options={})
          case attribute.name
          when :issue
            format_default_entity_attribute(attribute, unformatted_value, options)
          when :user
            unformatted_value&.name
          when :date
            format_date(unformatted_value)
          when :hours
            if options[:no_html]
              format_locale_number(unformatted_value)
            else
              easy_format_hours(unformatted_value, options)
            end
          end
        end
      end
    end

    def format_issue_attribute_with_easy_gantt_resources(entity_class, attribute, unformatted_value, options={})
      case attribute.name
      when :allocated_hours
        if options[:no_html]
          format_locale_number(unformatted_value)
        else
          easy_format_hours(unformatted_value, options)
        end
      else
        format_issue_attribute_without_easy_gantt_resources(entity_class, attribute, unformatted_value, options)
      end
    end

  end
end

RedmineExtensions::PatchManager.register_helper_patch 'EntityAttributeHelper', 'EasyGanttResources::EntityAttributeHelperPatch'
