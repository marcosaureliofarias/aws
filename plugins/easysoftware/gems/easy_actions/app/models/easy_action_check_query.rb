class EasyActionCheckQuery < EasyQuery

  def initialize_available_columns
    on_column_group(default_group_label) do
      add_available_column EasyQueryColumn.new(:entity_type, title: EasyActionCheck.human_attribute_name(:entity_type))
      add_available_column EasyQueryColumn.new(:entity_id, title: EasyActionCheck.human_attribute_name(:entity_id))
      add_available_column EasyQueryColumn.new(:entity, caption: :field_entity, preload: [:entity])
      add_available_column EasyQueryColumn.new(:status, title: EasyActionCheck.human_attribute_name(:status))
    end

    add_associated_columns EasyActionCheckTemplateQuery, association_name: :easy_action_check_template
  end

  def initialize_available_filters
    on_filter_group(default_group_label) do
      add_available_filter 'entity_type', name: EasyActionCheck.human_attribute_name(:entity_type)
      add_available_filter 'entity_id', name: EasyActionCheck.human_attribute_name(:entity_id)
      add_available_filter 'status', name: EasyActionCheck.human_attribute_name(:status)
    end
  end

  def default_group_label
    l("label_filter_group_#{self.class_name_underscored}", scope: :easy_actions)
  end

  def searchable_columns
    %w[templates.name]
  end

  def entity
    EasyActionCheck
  end

  def default_list_columns
    super.presence || %w[easy_action_check_template.name status entity]
  end

end
