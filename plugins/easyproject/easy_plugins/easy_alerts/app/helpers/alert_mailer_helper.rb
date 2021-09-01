module AlertMailerHelper

  def entity_attribute(entity, column, html = false)
    unformatted_value = column.value(entity)
    if html
      formatted_value = format_html_entity_attribute(entity.class, column, unformatted_value, {:no_link => true, :entity => entity, :editable => false, :allow_avatar => false})
    else
      formatted_value = format_entity_attribute(entity.class, column, unformatted_value, {entity: entity})
    end
    return formatted_value
  end

end