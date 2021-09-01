module EasyMoney
  class SettingsResolver

    attr_reader :project

    def initialize(settings_names, project = nil)
      raise ArgumentError, 'Names cannot be blank.' if settings_names.blank?

      @project = project
      settings_names -= EasyMoneySettings::SETTINGS_WITH_PRICE_RATE

      @settings = {}
      @settings.default_proc = proc do |_, name|
        settings_names.include?(name) ? EasyMoneySettings.find_settings_by_name(name, project) : nil
      end
    end

    def currency_easy_currency_code
      @current_easy_currency_code ||= project.try(:easy_currency_code) || EasyCurrency.default_code
    end

    def [](name)
      if name.in? EasyMoneySettings::SETTINGS_WITH_PRICE_RATE
        setting_with_currency name, currency_easy_currency_code
      else
        @settings[name]
      end
    end

    def show_price1?
      (@settings['price_visibility'] == 'all') || (@settings['price_visibility'] == 'price1')
    end

    def show_price2?
      (@settings['price_visibility'] == 'all') || (@settings['price_visibility'] == 'price2')
    end

    def show_rate?(rate_name)
      (@settings['rate_type'] == 'all') || (@settings['rate_type'] == rate_name)
    end

    def show_rate_internal?
      (@settings['rate_type'] == 'all') || (@settings['rate_type'] == 'internal')
    end

    def show_rate_external?
      (@settings['rate_type'] == 'all') || (@settings['rate_type'] == 'external')
    end

    def include_childs?
      @settings['include_childs'] == '1'
    end

    def use_travel_costs?
      @settings['use_travel_costs'] == '1'
    end

    def use_travel_expenses?
      @settings['use_travel_expenses'] == '1'
    end

    def travel_cost_price_per_unit(easy_currency_code = current_easy_currency_code)
      setting_with_currency 'travel_cost_price_per_unit', easy_currency_code
    end

    def travel_expense_price_per_day(easy_currency_code = current_easy_currency_code)
      setting_with_currency 'travel_expense_price_per_day', easy_currency_code
    end

    def travel_metric_unit
      @settings['travel_metric_unit'] || 'km'
    end

    def show_expected?
      @settings['expected_visibility'] == '1'
    end

    def currency_visible?
      @settings['currency_visible'] == '1'
    end

    def revenues_type
      @settings['revenues_type'] || 'list'
    end

    def expenses_type
      @settings['expenses_type'] || 'list'
    end

    def expected_payroll_expense_type
      @settings['expected_payroll_expense_type'] || 'amount'
    end

    def expected_payroll_expense_rate(easy_currency_code = currency_easy_currency_code)
      setting_with_currency 'expected_payroll_expense_rate', easy_currency_code
    end

    def expected_count_price
      @settings['expected_count_price'] || 'price1'
    end

    def expected_rate_type
      @settings['expected_rate_type'] || 'internal'
    end

    def vat
      @settings['vat']
    end

    def vat_disabled?
      false
    end

    def use_easy_money_for_versions?
      @settings['use_easy_money_for_versions'] == '1'
    end

    def use_easy_money_for_issues?
      @settings['use_easy_money_for_issues'] == '1'
    end

    def use_easy_money_for_easy_crm_cases?
      @settings['use_easy_money_for_easy_crm_cases'] == '1'
    end

    def round_on_list?
      @settings['round_on_list'] == '1'
    end

    def setting_with_currency(setting_name, currency_easy_currency_code)
      easy_money_rate = EasyMoneyRate.find_rate_for_setting(setting_name, project.try(:id))
      easy_money_rate.try(:unit_rate, currency_easy_currency_code) || 0.0
    end
  end
end
