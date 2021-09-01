class EasyEntityImportQuery < EasyQuery

  def initialize_available_filters
    on_filter_group(default_group_label) do
      add_available_filter 'name', { type: :string, order: 1 }
      add_available_filter 'is_automatic', { type: :boolean, order: 5 }
    end
  end

  def available_columns
    unless @available_columns_added
      group                    = l("label_filter_group_#{self.class.name.underscore}")
      @available_columns       = [
          EasyQueryColumn.new(:name, :sortable => "#{self.entity.table_name}.name", :groupable => true, :group => group),
          EasyQueryColumn.new(:is_automatic, :groupable => true, :sortable => "#{self.entity.table_name}.is_automatic", :group => group),
          EasyQueryColumn.new(:entity_type, :sortable => "#{self.entity.table_name}.entity_type", :groupable => true, :group => group),
          EasyQueryColumn.new(:type, :sortable => "#{self.entity.table_name}.type", :groupable => true, :group => group)
      ]
      @available_columns_added = true
    end
    @available_columns
  end

  def entity
    EasyEntityImport
  end

  def default_list_columns
    d = super
    d = %w{ name entity_type type} if d.empty?
    d
  end

end
