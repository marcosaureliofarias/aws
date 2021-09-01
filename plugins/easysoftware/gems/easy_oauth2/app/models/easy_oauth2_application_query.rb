class EasyOauth2ApplicationQuery < EasyQuery

  def initialize_available_columns
    on_column_group(default_group_label) do
      add_available_column EasyQueryColumn.new(:guid, title: EasyOauth2Application.human_attribute_name(:guid))
      add_available_column EasyQueryColumn.new(:name, title: EasyOauth2Application.human_attribute_name(:name))
      add_available_column EasyQueryColumn.new(:type, title: EasyOauth2Application.human_attribute_name(:type))
      add_available_column EasyQueryColumn.new(:active, title: EasyOauth2Application.human_attribute_name(:active))
      add_available_column EasyQueryColumn.new(:app_id, title: EasyOauth2Application.human_attribute_name(:app_id))
    end
  end

  def initialize_available_filters
    on_filter_group(default_group_label) do
      add_available_filter 'guid', name: EasyOauth2Application.human_attribute_name(:guid)
      add_available_filter 'name', name: EasyOauth2Application.human_attribute_name(:name)
      add_available_filter 'type', name: EasyOauth2Application.human_attribute_name(:type)
      add_available_filter 'active', name: EasyOauth2Application.human_attribute_name(:active)
      add_available_filter 'app_id', name: EasyOauth2Application.human_attribute_name(:app_id)
    end
  end

  def searchable_columns
    %w(#{EasyOauth2Application.table_name}.guid #{EasyOauth2Application.table_name}.name #{EasyOauth2Application.table_name}.app_id)
  end

  def entity
    EasyOauth2Application
  end

  def default_list_columns
    super.presence || %w[name guid type app_id]
  end

end
