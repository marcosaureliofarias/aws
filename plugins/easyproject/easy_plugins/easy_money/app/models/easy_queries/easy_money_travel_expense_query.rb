class EasyMoneyTravelExpenseQuery < EasyMoneyGenericQuery

  def self.permission_view_entities
    :easy_money_show_travel_expense
  end

  def entity
    EasyMoneyTravelExpense
  end

  def self.chart_support?
    true
  end

  def entity_custom_field
    EasyMoneyTravelExpenseCustomField
  end

  def initialize_available_filters
    super
    delete_available_filter('price2')
    delete_available_filter('vat')
    delete_available_filter('spent_on')

    on_filter_group(default_group_label) do
      add_available_filter 'spent_on', { type: :date_period, order: 2, name: l(:label_easy_money_travel_expense_spent_on_from) }
      add_available_filter 'spent_on_to', { type: :date_period, order: 3, name: l(:label_easy_money_travel_expense_spent_on_to) }
      add_available_filter 'price_per_day', { type: :float, order: 7, name: l(:label_easy_money_price_per_day) }
      add_principal_autocomplete_filter 'user_id', includes: [:user], order: 8
    end
  end

  def initialize_available_columns
    super

    delete_available_column :price2
    delete_available_column :vat

    group = default_group_label

    add_available_column :price_per_day, caption: :label_easy_money_price_per_day, sortable: "#{entity_table_name}.price_per_day", group: group, query: self
    add_available_column :spent_on_to, caption: :label_easy_money_travel_expense_spent_on_to, sortable: "#{entity_table_name}.spent_on_to", group: group

    user_group = l(:label_user_plural)

    add_available_column :user,
                         sortable: -> {User.fields_for_order_statement},
                         groupable: true,
                         includes: [user: :easy_avatar],
                         group: user_group

  end
end
