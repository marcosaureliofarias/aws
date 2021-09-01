class EasyActionSequenceTemplateQuery < EasyQuery

  def initialize_available_columns
    on_column_group(default_group_label) do
      add_available_column EasyQueryColumn.new(:name, title: EasyActionSequenceTemplate.human_attribute_name(:name))
      add_available_column EasyQueryColumn.new(:target_entity_class, title: EasyActionSequenceTemplate.human_attribute_name(:target_entity_class))
    end

    add_associated_columns EasyActionSequenceCategoryQuery, association_name: :easy_action_sequence_category
  end

  def initialize_available_filters
    on_filter_group(default_group_label) do
      add_available_filter 'name', name: EasyActionSequenceTemplate.human_attribute_name(:name)
      add_available_filter 'target_entity_class', name: EasyActionSequenceTemplate.human_attribute_name(:target_entity_class)
    end
  end

  def default_group_label
    l("label_filter_group_#{self.class_name_underscored}", scope: :easy_actions)
  end

  def searchable_columns
    ["#{EasyActionSequenceTemplate.table_name}.name"]
  end

  def entity
    EasyActionSequenceTemplate
  end

  def default_find_include
    [:easy_action_sequence_category]
  end

  def default_list_columns
    super.presence || %w[name easy_action_sequence_categories.name]
  end

end
