module EasyChecklistPlugin
  module EntityAttributeHelperPatch

    def self.included(base)
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      base.class_eval do

        def format_html_easy_checklist_template_attribute(entity_class, attribute, unformatted_value, options={})
          value = format_entity_attribute(entity_class, attribute, unformatted_value, options)

          case attribute.name
            when :name
              if value
                link_to(value, edit_easy_checklist_path(options[:entity]))
              else
                h(value)
              end
            when :author
              content_tag(:span, render_user_attribute(unformatted_value, value, options)) if value
            else
              h(value)
          end
        end

      end
    end

    module InstanceMethods
    end

    module ClassMethods
    end

  end
end

RedmineExtensions::PatchManager.register_helper_patch 'EntityAttributeHelper', 'EasyChecklistPlugin::EntityAttributeHelperPatch', if: proc { Redmine::Plugin.installed?(:easy_extensions) }
