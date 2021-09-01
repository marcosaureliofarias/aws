class EasyUserTargetQuery < EasyQuery

  def initialize_available_filters
    on_filter_group(default_group_label) do
      add_principal_autocomplete_filter 'user_id', { name: EasyUserTarget.human_attribute_name(:user_id) }
      add_available_filter 'target', { name: EasyUserTarget.human_attribute_name(:target), type: :currency }
      # add_available_filter 'currency', { name: EasyUserTarget.human_attribute_name(:currency), type: :string }
      add_available_filter 'valid_from', { name: EasyUserTarget.human_attribute_name(:valid_from), type: :date_period }
      # add_available_filter 'valid_to', { name: EasyUserTarget.human_attribute_name(:valid_to), type: :date_period }
    end
  end

  def initialize_available_columns
    group = default_group_label
    add_available_column :user, title: EasyUserTarget.human_attribute_name(:user_id), sortable: lambda { User.fields_for_order_statement }, groupable: true, includes: [:user], group: group
    add_available_column EasyQueryCurrencyColumn.new(:target, sortable: "#{EasyUserTarget.table_name}.target", sumable: :both, query: self, sumable_options: {model: 'EasyUserTarget', column: 'target', distinct_columns: [["#{EasyUserTarget.table_name}.id", :easy_user_target]]}, group: group)
    add_available_column :currency, sortable: "#{EasyUserTarget.table_name}.currency", title: EasyUserTarget.human_attribute_name(:currency), group: group
    add_available_column :valid_from, sortable: "#{EasyUserTarget.table_name}.valid_from", title: EasyUserTarget.human_attribute_name(:valid_from), group: group
    # add_available_column :valid_to, sortable: "#{EasyUserTarget.table_name}.valid_to", title: EasyUserTarget.human_attribute_name(:valid_to), group: group
  end

  def entity
    EasyUserTarget
  end

  def self.chart_support?
    true
  end

  def self.report_support?
    false
  end

  def entity_easy_query_path(options = {})
    easy_user_targets_path(options)
  end

  def default_list_columns
    d = super
    d = %w{ user target valid_from } if d.empty?
    d
  end

end
