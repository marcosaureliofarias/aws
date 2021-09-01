class EasyCustomFieldGroup < Enumeration

  has_many :custom_fields, foreign_key: 'easy_group_id'

  OptionName = :enumeration_easy_custom_field_group

  def option_name
    OptionName
  end

  def objects
    CustomField.where(:easy_group_id => id)
  end

  def objects_count
    custom_fields.count
  end

  def to_s
    name
  end

  def transfer_relations(to)
    objects.update_all(:easy_group_id => to.id)
  end

end
