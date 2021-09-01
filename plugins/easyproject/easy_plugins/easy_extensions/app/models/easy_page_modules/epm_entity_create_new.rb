class EpmEntityCreateNew < EasyPageModule

  def entity
    raise ArgumentError, 'Entity cannot be null.'
  end

  def new_entity
    @new_entity = entity.new
  end

  def entity_name
    entity.name
  end

  def edit_path
    'easy_page_modules/entity_create_new_edit'
  end

  def get_edit_data(settings, user, page_context = {})
    {
        entity_name:                        entity_name.underscore,
        available_fields:                   available_fields,
        options_for_show_fields:            options_for_show_fields,
        grouped_entity_custom_field_values: grouped_entity_custom_field_values
    }
  end

  def available_fields
    raise ArgumentError, 'Available fields cannot be null.'
  end

  def options_for_show_fields
    [
        [l(:general_all), 'all'],
        [l(:general_only_required), 'only_required'],
        [l(:option_only_selected), 'only_selected']
    ]
  end

  def all_principals
    p = User.non_system_flag.active.sorted.to_a
    p.concat(Group.givable.active.non_system_flag.sorted.to_a) if Setting.issue_group_assignment?
    p
  end

  def visible_entity_custom_fields
    CustomField.where("type = '#{entity_name}CustomField'").visible.sorted.to_a
  end

  def visible_entity_custom_field_values
    visible_entity_custom_fields.collect do |field|
      x              = CustomFieldValue.new
      x.custom_field = field
      x.customized   = new_entity
      if field.multiple?
        values = new_entity.custom_values.select { |v| v.custom_field == field }
        if values.empty?
          values << new_entity.custom_values.build(customized: new_entity, custom_field: field)
        end
        x.instance_variable_set("@value", values.map(&:value))
      else
        cv = new_entity.custom_values.detect { |v| v.custom_field == field }
        cv ||= new_entity.custom_values.build(customized: new_entity, custom_field: field)
        x.instance_variable_set("@value", cv.value)
      end
      x.value_was = x.value.dup if x.value
      x
    end
  end

  def grouped_entity_custom_field_values
    new_entity.grouped_custom_field_values(visible_entity_custom_field_values)
  end

  def required_entity_custom_field_ids
    visible_entity_custom_field_values.select { |cfv| cfv.custom_field.is_required }.map { |cfv| cfv.custom_field.id.to_s }
  end

  def required_entity_fields
    entity.validators.map do |validator|
      validator.attributes if validator.is_a?(ActiveRecord::Validations::PresenceValidator)
    end.compact.flatten
  end

end