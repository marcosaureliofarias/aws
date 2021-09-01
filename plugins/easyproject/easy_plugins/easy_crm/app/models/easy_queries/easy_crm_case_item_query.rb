class EasyCrmCaseItemQuery < EasyQuery

  def self.permission_view_entities
    :view_easy_crms
  end

  def initialize_available_filters
    group = default_group_label

    add_available_filter 'name', {:type => :string, :order => 1, :group => group, :name => EasyCrmCaseItem.human_attribute_name(:name)}
    add_available_filter 'description', {:type => :string, :order => 1, :group => group, :name => EasyCrmCaseItem.human_attribute_name(:description)}
    add_available_filter 'total_price', {:type => :currency, :order => 5, :group => group, :name => EasyCrmCaseItem.human_attribute_name(:total_price)}
    add_available_filter 'product_code', {:type => :string, :order => 1, :group => group, :name => EasyCrmCaseItem.human_attribute_name(:product_code)}
    add_available_filter 'amount', {:type => :float, :order => 5, :group => group, :name => EasyCrmCaseItem.human_attribute_name(:amount)}
    add_available_filter 'unit', {:type => :string, :order => 1, :group => group, :name => EasyCrmCaseItem.human_attribute_name(:unit)}
    add_available_filter 'price_per_unit', {:type => :currency, :order => 5, :group => group, :name => EasyCrmCaseItem.human_attribute_name(:price_per_unit)}
    add_available_filter 'discount', { :type => :float, :order => 5, :group => group, :name => EasyCrmCaseItem.human_attribute_name(:discount) }
    add_available_filter 'easy_external_id', { type: :string }
  end

  def initialize_available_columns
    group = default_group_label

    add_available_column EasyQueryColumn.new(:name, sortable: "#{EasyCrmCaseItem.table_name}.name", title: EasyCrmCaseItem.human_attribute_name(:name), groupable: true, group: group)
    add_available_column EasyQueryCurrencyColumn.new(:total_price, sortable: "#{EasyCrmCaseItem.table_name}.total_price", title: EasyCrmCaseItem.human_attribute_name(:total_price), sumable: true, group: group, query: self)
    add_available_column EasyQueryColumn.new(:product_code, sortable: "#{EasyCrmCaseItem.table_name}.product_code", title: EasyCrmCaseItem.human_attribute_name(:product_code), groupable: true, group: group)
    add_available_column EasyQueryColumn.new(:amount, sortable: "#{EasyCrmCaseItem.table_name}.amount", title: EasyCrmCaseItem.human_attribute_name(:amount), sumable: true, group: group)
    add_available_column EasyQueryColumn.new(:unit, sortable: "#{EasyCrmCaseItem.table_name}.unit", title: EasyCrmCaseItem.human_attribute_name(:unit), group: group)
    add_available_column EasyQueryCurrencyColumn.new(:price_per_unit, sortable: "#{EasyCrmCaseItem.table_name}.price_per_unit", title: EasyCrmCaseItem.human_attribute_name(:price_per_unit), sumable: true, group: group, query: self)
    add_available_column EasyQueryColumn.new(:discount, sortable: "#{EasyCrmCaseItem.table_name}.discount", title: EasyCrmCaseItem.human_attribute_name(:discount), sumable: true, group: group)
    add_available_column EasyQueryColumn.new(:easy_external_id, caption: :field_easy_external,  group: group)

    add_associated_columns EasyCrmCaseQuery
  end

  def searchable_columns
    ["#{EasyCrmCaseItem.table_name}.name"]
  end

  def entity
    EasyCrmCaseItem
  end

  def entity_easy_query_path(options = {})
    easy_crm_case_items_path(options)
  end

  def self.chart_support?
    true
  end

  def default_list_columns
    d = super
    d = %w{ amount unit product_code name price_per_unit total_price  } if d.empty?
    d
  end

end
