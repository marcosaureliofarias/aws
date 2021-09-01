class EasyActionSequenceQuery < EasyQuery

  def initialize_available_columns
    on_column_group(default_group_label) do
      add_available_column EasyQueryColumn.new(:entity_type, title: EasyActionSequence.human_attribute_name(:entity_type))
      add_available_column EasyQueryColumn.new(:entity_id, title: EasyActionSequence.human_attribute_name(:entity_id))
      add_available_column EasyQueryColumn.new(:entity, caption: :field_entity, preload: [:entity])
    end

    add_associated_columns EasyActionSequenceTemplateQuery, association_name: :template
  end

  def initialize_available_filters
    on_filter_group(default_group_label) do
      add_available_filter 'entity_type', name: EasyActionSequence.human_attribute_name(:entity_type)
      add_available_filter 'entity_id', name: EasyActionSequence.human_attribute_name(:entity_id)
    end
    add_associations_filters EasyActionSequenceTemplateQuery
  end

  def default_group_label
    l("label_filter_group_#{self.class_name_underscored}", scope: :easy_actions)
  end

  def template_group_label
    l("label_filter_group_easy_action_sequence_template_query", scope: :easy_actions)
  end

  def searchable_columns
    %w[templates.name]
  end

  def entity
    EasyActionSequence
  end

  def default_find_include
    [:template]
  end

  def default_list_columns
    super.presence || %w[templates.name entity]
  end

end
