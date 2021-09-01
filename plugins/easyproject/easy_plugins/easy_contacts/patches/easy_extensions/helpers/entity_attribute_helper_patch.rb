module EasyContacts
  module EntityAttributeHelperPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        alias_method_chain :format_html_issue_attribute, :easy_contacts

        def format_html_easy_contact_group_attribute(entity_class, attribute, unformatted_value, options={})
          value = format_entity_attribute(entity_class, attribute, unformatted_value, options)

          case attribute.name
          when :group_name
            link_to(value, options[:entity])
          when :group_type
            l(value)
          else
            h(value)
          end
        end

        def format_html_easy_contact_attribute(entity_class, attribute, unformatted_value, options={})
          value = format_entity_attribute(entity_class, attribute, unformatted_value, options)

          if options[:entity]&.visible?
            case attribute.name
            when :firstname, :lastname, :name
              if options[:no_link] || value.blank?
                h(value)
              else
                link_to(value, polymorphic_path((@project.nil? || @project.new_record?) ? options[:entity] : [@project, options[:entity]]))
              end
            when :groups
              if value.nil? || value.blank?
                l(:label_none)
              else
                value.join(', ')
              end
            when :contact_name
              if options[:no_link]
                content_tag(:span, h(value), :class => options[:entity].css_icon)
              else
                link_to(value, easy_contact_path(options[:entity], :project_id => @project), :class => options[:entity].css_icon) unless value.blank?
              end
            when :name_and_cf
              name_link = link_to(options[:entity].name, easy_contact_path(options[:entity], :project_id => @project))
              "#{name_link} - #{get_attribute_custom_field_formatted_value(options[:entity], attribute, :html => true)}"
            else
              h(value)
            end
          else
            '---'
          end

        end

      end
    end

    module InstanceMethods

      def format_html_issue_attribute_with_easy_contacts(entity_class, attribute, unformatted_value, options={})
        case attribute.name
        when :easy_contacts
          if unformatted_value.any? && options[:entity]
            l(:label_relates_to).concat(unformatted_value.collect {|related_contact| " #{link_to_easy_contact(related_contact)}"}.join(', ').html_safe)
          end
        else
          format_html_issue_attribute_without_easy_contacts(entity_class, attribute, unformatted_value, options)
        end
      end

    end
  end

end
EasyExtensions::PatchManager.register_helper_patch('EntityAttributeHelper', 'EasyContacts::EntityAttributeHelperPatch')
