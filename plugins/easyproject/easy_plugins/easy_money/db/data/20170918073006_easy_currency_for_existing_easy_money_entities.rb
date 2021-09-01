class EasyCurrencyForExistingEasyMoneyEntities < EasyExtensions::EasyDataMigration
  def up
    setting = EasySetting.find_or_initialize_by(name: 'easy_currencies_initialized', project_id: nil)
    setting.value = false
    setting.save

    return if EasyCurrency.activated.empty?

    adapter_name = connection.adapter_name.underscore

    [
        EasyMoneyExpectedRevenue,
        EasyMoneyExpectedExpense,
        EasyMoneyOtherRevenue,
        EasyMoneyOtherExpense,
        EasyMoneyTravelCost,
        EasyMoneyTravelExpense,
        EasyMoneyExpectedPayrollExpense,
        EasyMoneyRate,
        EasyMoneyProjectCache
    ].each do |klass|
      method_name = "easy_money_entity_setup_currency_for_#{adapter_name}"

      if respond_to? method_name
        public_send method_name, klass
      else
        raise "Unsupported adapter #{adapter_name}"
      end

      klass.where(easy_currency_code: nil).update_all(easy_currency_code: EasyCurrency.default_code)
    end

    EasyMoneyExpectedPayrollExpense.where(updated_at: nil).update_all(updated_at: Time.zone.now)
    EasyMoneyRate.where(updated_at: nil).update_all(updated_at: Time.zone.now)

    method_name = "periodical_entity_items_setup_currency_for_#{adapter_name}"
    if respond_to? method_name
      public_send method_name
    else
      raise "Unsupported adapter #{adapter_name}"
    end

    EasyMoneyPeriodicalEntityItem.where(easy_currency_code: nil).update_all(easy_currency_code: EasyCurrency.default_code)

    EasyMoneySettings.where(name: EasyMoneySettings::SETTINGS_WITH_PRICE_RATE).where.not(value: [nil, '', '0']).each(&:save)
  end

  def easy_money_entity_setup_currency_for_mysql2(klass)
    klass.joins(:project).update_all("#{klass.table_name}.easy_currency_code = projects.easy_currency_code")
  end

  def easy_money_entity_setup_currency_for_postgre_sql(klass)
    sql = <<-SQL
      UPDATE #{klass.table_name}
      SET easy_currency_code = projects.easy_currency_code
      FROM projects
      WHERE #{klass.table_name}.project_id = projects.id
    SQL

    execute sql
  end

  def periodical_entity_items_setup_currency_for_mysql2
    EasyMoneyPeriodicalEntityItem.joins(easy_money_periodical_entity: :project).update_all("easy_money_periodical_entity_items.easy_currency_code = projects.easy_currency_code")
  end

  def periodical_entity_items_setup_currency_for_postgre_sql
    sql = <<-SQL
      UPDATE easy_money_periodical_entity_items
      SET easy_currency_code = projects.easy_currency_code
      FROM easy_money_periodical_entities, projects
      WHERE
          easy_money_periodical_entity_items.easy_money_periodical_entity_id = easy_money_periodical_entities.id
          AND easy_money_periodical_entities.project_id = projects.id
    SQL

    execute sql
  end
end
