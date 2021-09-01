Rys::Patcher.add('EntityAttributeHelper') do

  apply_if_plugins :easy_extensions

  included do

    def format_html_easy_oauth2_application_attribute(entity_class, attribute, unformatted_value, options = {})
      value = format_entity_attribute(entity_class, attribute, unformatted_value, options)

      case attribute.name
      when :name
        link_to(value, easy_oauth2_application_path(options[:entity]))
      else
        h(value)
      end
    end

  end

end
