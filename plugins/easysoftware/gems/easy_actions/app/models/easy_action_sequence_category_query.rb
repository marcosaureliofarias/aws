class EasyActionSequenceCategoryQuery < EasyQuery

  def initialize_available_columns
    on_column_group(default_group_label) do
      add_available_column EasyQueryColumn.new(:name, title: EasyActionSequenceCategory.human_attribute_name(:name))
      add_available_column EasyQueryColumn.new(:description, title: EasyActionSequenceCategory.human_attribute_name(:description))
    end
  end

  def initialize_available_filters
    on_filter_group(default_group_label) do
      add_available_filter 'name', name: EasyActionSequenceCategory.human_attribute_name(:name)
      add_available_filter 'description', name: EasyActionSequenceCategory.human_attribute_name(:description)
    end
  end

  def default_group_label
    l("label_filter_group_#{self.class_name_underscored}", scope: :easy_actions)
  end

  def searchable_columns
    ["#{EasyActionSequenceCategory.table_name}.name"]
  end

  def entity
    EasyActionSequenceCategory
  end

  def default_list_columns
    super.presence || ['name']
  end

end
