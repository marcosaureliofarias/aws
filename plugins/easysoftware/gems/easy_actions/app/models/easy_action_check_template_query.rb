class EasyActionCheckTemplateQuery < EasyQuery

  def initialize_available_columns
    on_column_group(default_group_label) do
      add_available_column EasyQueryColumn.new(:name, title: EasyActionCheckTemplate.human_attribute_name(:name))
    end
  end

  def initialize_available_filters
    on_filter_group(default_group_label) do
      add_available_filter 'name', name: EasyActionCheckTemplate.human_attribute_name(:name)
    end
  end

  def default_group_label
    l("label_filter_group_#{self.class_name_underscored}", scope: :easy_actions)
  end

  def searchable_columns
    ["#{EasyActionCheckTemplate.table_name}.name"]
  end

  def entity
    EasyActionCheckTemplate
  end

  def default_list_columns
    super.presence || ['name']
  end

end
