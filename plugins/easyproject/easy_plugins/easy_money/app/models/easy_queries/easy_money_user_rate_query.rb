class EasyMoneyRateColumn < EasyEntityAttribute
  attr_accessor :sortable, :groupable, :default_order
  attr_reader :rate_type, :query

  delegate :project, to: :query, allow_nil: true
  delegate :easy_currency_code, to: :project, allow_nil: true, prefix: true

  def initialize(rate_type, options={})
    @rate_type = rate_type
    @query = options[:query]

    options[:caption] = "easy_money_rate_type.#{rate_type.name}"

    super(unit_rate_column, options)
  end

  def unit_rate_column
    "rate_type_#{rate_type.id}_unit_rate"
  end

  def unit_rate_currency_column
    "rate_type_#{rate_type.id}_easy_currency_code"
  end

  def project_currency_unit_rate_column
    if project_easy_currency_code
      "rate_type_#{rate_type.id}_unit_rate_#{project_easy_currency_code}".downcase
    end
  end

  def easy_money_rates_table_name
    "easy_money_rates_#{rate_type.id}"
  end

  def select_columns
    [
        easy_money_rates_table[:unit_rate].as(unit_rate_column),
        easy_money_rates_table[:easy_currency_code].as(unit_rate_currency_column)
    ].push(*project_specific_columns)
  end

  def easy_money_rates_table
    @easy_money_rates_table ||= EasyMoneyRate.arel_table.alias(easy_money_rates_table_name)
  end

  def joins
    project ? join_for_project_rates : join_for_global_rates
  end

  def join_for_global_rates
    users_table = User.arel_table

    users_table.join(easy_money_rates_table, Arel::Nodes::OuterJoin)
        .on(
            easy_money_rates_table[:entity_id].eq(users_table[:id])
                .and(easy_money_rates_table[:entity_type].eq 'Principal')
                .and(easy_money_rates_table[:rate_type_id].eq rate_type.id)
                .and(easy_money_rates_table[:project_id].eq nil)
        ).join_sources
  end

  def join_for_project_rates
    easy_money_rates_table = EasyMoneyRate.arel_table
    users_table = User.arel_table

    subquery = easy_money_rates_table
                   .where(easy_money_rates_table[:entity_type].eq 'Principal')
                   .where(easy_money_rates_table[:rate_type_id].eq rate_type.id)
                   .where(
                       easy_money_rates_table[:project_id].eq(project.id)
                           .or(easy_money_rates_table[:project_id].eq(nil))
                   )
                   .group(easy_money_rates_table[:entity_id])
                   .project(
                       easy_money_rates_table[:entity_id],
                       Arel::Nodes::NamedFunction.new('COALESCE', [easy_money_rates_table[:project_id].maximum, 0]).as('project_id')
                   ).as('subquery')

    join_table = easy_money_rates_table.join(subquery).on(
        subquery[:entity_id].eq(easy_money_rates_table[:entity_id]).and(
            subquery[:project_id].eq Arel::Nodes::NamedFunction.new('COALESCE', [easy_money_rates_table[:project_id], 0])
        )
    )

    if project_easy_currency_code
      join_table.join(exchange_rates_table, Arel::Nodes::OuterJoin).on(
          exchange_rates_table[:base_code].eq(easy_money_rates_table[:easy_currency_code]).and(
              exchange_rates_table[:to_code].eq(project_easy_currency_code)
          )
      )

      join_table.projections << (easy_money_rates_table[:unit_rate] * Arel::Nodes::NamedFunction.new('COALESCE', [exchange_rates_table[:rate], 1])).as("unit_rate_#{project_easy_currency_code}".downcase)
    end

    join_table.where(easy_money_rates_table[:entity_type].eq 'Principal').where(easy_money_rates_table[:rate_type_id].eq rate_type.id)
    join_table.projections << easy_money_rates_table[Arel.star]
    join_table = join_table.as(easy_money_rates_table_name)

    users_table.join(join_table, Arel::Nodes::OuterJoin)
        .on(join_table[:entity_id].eq users_table[:id])
        .join_sources
  end

  def exchange_rates_table
    @exchange_rates_table ||= begin
      easy_currency_exchange_rates_table = EasyCurrencyExchangeRate.arel_table

      exchange_helper_table = easy_currency_exchange_rates_table
                                  .group(easy_currency_exchange_rates_table[:base_code], easy_currency_exchange_rates_table[:to_code])
                                  .project(easy_currency_exchange_rates_table[:base_code], easy_currency_exchange_rates_table[:to_code], easy_currency_exchange_rates_table[:valid_on].maximum.as('valid_on'))
                                  .as('easy_currency_exchange_rates_helper')

      easy_currency_exchange_rates_table
          .join(exchange_helper_table).on(
          easy_currency_exchange_rates_table[:base_code].eq(exchange_helper_table[:base_code]).and(
              easy_currency_exchange_rates_table[:to_code].eq(exchange_helper_table[:to_code]).and(
                  easy_currency_exchange_rates_table[:valid_on].eq(exchange_helper_table[:valid_on])
              )
          )
      ).project(easy_currency_exchange_rates_table[Arel.star]).as('easy_currency_exchange_rates')
    end
  end

  def project_specific_columns
    if project_currency_unit_rate_column
      [easy_money_rates_table["unit_rate_#{project_easy_currency_code}".downcase].as(project_currency_unit_rate_column)]
    end
  end

  def sortable?
    false
  end
end

class EasyMoneyUserRateQuery < EasyUserQuery
  def self.entity_css_classes(entity, options={})
    "multieditable-container"
  end

  def default_group_label
    l(:label_filter_group_easy_user_query)
  end

  def default_list_columns
    available_columns.map{|column| column.name.to_s}
  end

  def default_sort_criteria
    @default_sort_criteria ||= User.fields_for_order_statement
  end

  def available_columns
    unless @available_columns_added
      @available_columns = [
          EasyQueryColumn.new(:name, sortable: lambda {User.fields_for_order_statement})
      ]

      available_rate_types.each do |rate_type|
        @available_columns << EasyMoneyRateColumn.new(rate_type, query: self)
      end
      @available_columns_added = true
    end
    @available_columns
  end

  def export_formats
    {}
  end

  def query_after_initialize
    super

    self.display_outputs_select_on_index = false
    self.display_filter_columns_on_index = false
    self.display_filter_group_by_on_index = false
    self.display_filter_settings_on_index = false

    self.display_filter_columns_on_edit = false
    self.display_filter_group_by_on_edit = false
    self.display_filter_settings_on_edit = false
  end

  def available_rate_types
    @available_rate_types = required_rate_type == 'all' ? EasyMoneyRateType.rate_type_cache : EasyMoneyRateType.rate_type_cache.find_all{|rate_type| rate_type.name == required_rate_type}
  end

  def required_rate_type
    EasyMoneySettings.find_settings_by_name('rate_type', project)
  end

  def entity_scope
    @entity_scope ||= begin
      scope = project ? project.users : User.active
      scope.non_system_flag.easy_type_internal.select(*entity_select_columns)
    end
  end

  def entity_select_columns
    Array.new.tap do |list|
      list << entity.arel_table[Arel.star]

      columns.each do |column|
        if column.respond_to?(:select_columns)
          list.push *column.select_columns
        end
      end
    end
  end

  def easy_query_entity_controller
    'easy_money_rates'
  end

end
