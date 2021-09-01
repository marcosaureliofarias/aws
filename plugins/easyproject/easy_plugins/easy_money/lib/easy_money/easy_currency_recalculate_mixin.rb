module EasyMoney
  module EasyCurrencyRecalculateMixin
    def recalculate_prices_in_currencies
      adapter_name = connection.adapter_name.underscore
      method_name = "recalculate_prices_in_currencies_for_#{adapter_name}"
      if respond_to?(method_name, true)
        __send__ method_name
      end
    end

    private

    def recalculate_prices_in_currencies_for_mysql2
      update_columns = []

      currency_options.each do |options|
        price_column = options[:price_method]

        EasyCurrency.active_currencies_codes.each do |easy_currency_code|
	  update_columns << "#{table_name}.#{price_column}_#{easy_currency_code} = #{table_name}.#{price_column} * exchange_rates.rate_#{easy_currency_code}"
        end
      end

      sql = <<-SQL
        UPDATE #{table_name}
        JOIN #{exchange_rates_table.to_sql} ON #{table_name}.id = exchange_rates.entity_id
        SET #{update_columns.join(', ')}
      SQL

      connection.execute sql
    end

    def recalculate_prices_in_currencies_for_postgre_sql
      update_columns = []

      currency_options.each do |options|
        price_column = options[:price_method]

        EasyCurrency.active_currencies_codes.each do |easy_currency_code|
          update_columns << %Q{"#{price_column}_#{easy_currency_code}" = #{price_column} * exchange_rates.rate_#{easy_currency_code}}
        end
      end

      sql = <<-SQL
        UPDATE #{table_name}
        SET #{update_columns.join(', ')}
        FROM #{exchange_rates_table.to_sql}
        WHERE #{table_name}.id = exchange_rates.entity_id
      SQL

      connection.execute sql
    end

    def entity_table_with_easy_currency_columns
      arel_table
    end

    def default_easy_currency_options
      currency_options.first
    end

    def exchange_rates_table(currency_options = default_easy_currency_options)
      entity_currency_column = currency_options[:currency_method]
      entity_exchange_date_column = currency_options[:exchange_rate_date]

      easy_currency_exchange_rates_table = EasyCurrencyExchangeRate.arel_table

      exchange_helper_table = Arel::SelectManager.new(entity_table_with_easy_currency_columns).join(easy_currency_exchange_rates_table)
                                  .on(
                                      easy_currency_exchange_rates_table[:base_code].eq(entity_table_with_easy_currency_columns[entity_currency_column])
                                          .and(easy_currency_exchange_rates_table[:valid_on].lteq Arel::Nodes::NamedFunction.new('DATE', [entity_table_with_easy_currency_columns[entity_exchange_date_column]]))
                                  )
                                  .group(entity_table_with_easy_currency_columns[:id], entity_table_with_easy_currency_columns[entity_currency_column])
                                  .project(
                                      entity_table_with_easy_currency_columns[:id].as('entity_id'),
                                      entity_table_with_easy_currency_columns[entity_currency_column].as('entity_currency_code'),
                                      easy_currency_exchange_rates_table[:valid_on].maximum.as('exchange_date')
                                  )
                                  .as('exchange_helper')

      select_manager = Arel::SelectManager.new(exchange_helper_table)
      select_manager.project(exchange_helper_table[:entity_id])

      EasyCurrency.active_currencies_codes.each do |easy_currency_code|
        currency_exchange_table = easy_currency_exchange_rates_table.alias("exchange_#{easy_currency_code}")

        select_manager = select_manager.join(currency_exchange_table, Arel::Nodes::OuterJoin)
                             .on(
                                 currency_exchange_table[:valid_on].eq(exchange_helper_table[:exchange_date])
                                     .and(
                                         currency_exchange_table[:base_code].eq(exchange_helper_table[:entity_currency_code])
                                             .and(currency_exchange_table[:to_code].eq easy_currency_code)
                                     )
                             )

        select_manager.project Arel::Nodes::NamedFunction.new('COALESCE', [currency_exchange_table[:rate], 1]).as("rate_#{easy_currency_code}")
      end

      select_manager.as('exchange_rates')
    end
  end
end
