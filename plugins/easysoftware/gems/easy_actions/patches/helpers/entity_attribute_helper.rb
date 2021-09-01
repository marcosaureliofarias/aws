Rys::Patcher.add('EntityAttributeHelper') do

  apply_if_plugins :easy_extensions

  included do

    def format_html_easy_action_check_template_attribute(entity_class, attribute, unformatted_value, options = {})
      value = format_entity_attribute(entity_class, attribute, unformatted_value, options)

      case attribute.name
      when :name, :id
        link_to(value, edit_easy_action_check_template_path(options[:entity]))
      else
        h(value)
      end
    end

    def format_html_easy_action_sequence_template_attribute(entity_class, attribute, unformatted_value, options = {})
      value = format_entity_attribute(entity_class, attribute, unformatted_value, options)

      case attribute.name
      when :name, :id
        link_to(value, easy_action_sequence_template_path(options[:entity]))
      else
        h(value)
      end
    end

    def format_html_easy_action_sequence_instance_attribute(entity_class, attribute, unformatted_value, options = {})
      value = format_entity_attribute(entity_class, attribute, unformatted_value, options)

      case attribute.name
      when :id
        link_to(value, easy_action_sequence_instance_path(options[:entity]))
      when :status
        format_easy_action_sequence_instance_status(options[:entity])
      when :entity
        link_to_entity(unformatted_value)
      else
        h(value)
      end
    end

    def format_html_easy_action_sequence_attribute(entity_class, attribute, unformatted_value, options = {})
      value = format_entity_attribute(entity_class, attribute, unformatted_value, options)

      case attribute.name
      when :id
        link_to(value, easy_action_sequence_path(options[:entity]))
      when :entity
        link_to_entity(unformatted_value)
      else
        h(value)
      end
    end

  end

end
