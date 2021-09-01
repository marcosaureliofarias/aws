module EasyTimesheets
  module EntityAttributeHelperPatch

    def self.included(base)

      base.class_eval do

        def format_html_easy_timesheet_attribute(entity_class, attribute, unformatted_value, options={})
          options[:inline_editable] = true
          value = format_entity_attribute(entity_class, attribute, unformatted_value, options)

          case attribute.name
          when :title
            if entity = options[:entity]
              link_to(entity, entity.monthly? ? monthly_show_easy_timesheets_path(entity) : entity)
            else
              h(value)
            end
          else
            h(value)
          end
        end

      end
    end

  end

end
EasyExtensions::PatchManager.register_helper_patch 'EntityAttributeHelper', 'EasyTimesheets::EntityAttributeHelperPatch'
