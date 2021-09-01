class EasyCrmCountryValueQuery < EasyQuery

  self.queried_class = EasyCrmCountryValue

  def initialize_available_filters
    add_available_filter 'country', name: ::EasyCrmCountryValue.human_attribute_name(:country), type: :string
    add_available_filter 'created_at', name: ::EasyCrmCountryValue.human_attribute_name(:created_at), type: :date
    add_available_filter 'updated_at', name: ::EasyCrmCountryValue.human_attribute_name(:updated_at), type: :date
    add_custom_fields_filters(EasyCrmCountryValueCustomField)
  end

  def available_columns
    return @available_columns if @available_columns

    add_available_column 'country', title: ::EasyCrmCountryValue.human_attribute_name(:country)
    add_available_column 'created_at', title: ::EasyCrmCountryValue.human_attribute_name(:created_at)
    add_available_column 'updated_at', title: ::EasyCrmCountryValue.human_attribute_name(:updated_at)

    @available_columns.concat(EasyCrmCountryValueCustomField.visible.collect {|cf| EasyQueryCustomFieldColumn.new(cf) })

    @available_columns
  end

  def default_columns_names
    super.presence || [:country, :created_at, :updated_at].flat_map{|c| [c.to_s, c.to_sym]}
  end

  def self.report_support?
    false
  end

end
