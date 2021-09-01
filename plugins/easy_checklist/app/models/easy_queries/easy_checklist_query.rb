class EasyChecklistQuery < EasyQuery

  def initialize_available_filters
    on_filter_group(default_group_label) do
      add_principal_autocomplete_filter 'author_id'
      add_available_filter'name', { type: :string, order: 2 }
    end
  end

  def initialize_available_columns
    add_available_column EasyQueryColumn.new(:author, sortable: proc { User.fields_for_order_statement }, group: default_group_label)
    add_available_column EasyQueryColumn.new(:name, sortable: "#{EasyChecklist.table_name}.name", group: default_group_label)
  end

  def entity_scope
    EasyChecklistTemplate.visible
  end

  def entity
    EasyChecklist
  end

  def default_list_columns
    super.presence || ['name', 'author']
  end

  def default_find_include
    [:author]
  end

  def searchable_columns
    ["#{User.table_name}.firstname", "#{User.table_name}.lastname", "#{EasyChecklist.table_name}.name"]
  end

end if Redmine::Plugin.installed?(:easy_extensions)
