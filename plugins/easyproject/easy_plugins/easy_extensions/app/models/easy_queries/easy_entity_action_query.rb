class EasyEntityActionQuery < EasyQuery

  def initialize_available_filters
    on_filter_group(default_group_label) do
      add_available_filter 'name', { type: :string, order: 1 }
    end
  end

  def initialize_available_columns
    on_column_group(default_group_label) do
      add_available_column 'name', sortable: "#{entity.quoted_table_name}.name"
    end
  end

  def searchable_columns
    ["#{EasyEntityAction.table_name}.name"]
  end

  def entity
    EasyEntityAction
  end

  def default_list_columns
    super.presence || ['name']
  end

end
