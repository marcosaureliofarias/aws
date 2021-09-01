class EasyMoneyTravelCostQuery < EasyMoneyGenericQuery

  def self.permission_view_entities
    :easy_money_show_travel_cost
  end

  def entity
    EasyMoneyTravelCost
  end

  def self.chart_support?
    true
  end

  def entity_custom_field
    EasyMoneyTravelCostCustomField
  end

  def initialize_available_filters
    super
    delete_available_filter('price2')
    delete_available_filter('vat')

    on_filter_group(default_group_label) do
      add_available_filter 'price_per_unit', { type: :float, order: 10, name: l(:field_easy_money_price_per_unit) }
      add_available_filter 'metric_units', { type: :float, order: 11, name: l(:field_easy_money_metric_units) }
    end
  end

  def initialize_available_columns
    super

    delete_available_column :price2
    delete_available_column :vat

    group = default_group_label

    add_available_column :price_per_unit, caption: :field_easy_money_price_per_unit, sortable: "#{entity_table_name}.price_per_unit", group: group, query: self
    add_available_column :metric_units, caption: :field_easy_money_metric_units, sortable: "#{entity_table_name}.metric_units", group: group
  end
end
