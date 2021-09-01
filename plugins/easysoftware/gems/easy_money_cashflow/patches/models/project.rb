Rys::Patcher.add('Project') do
  apply_if_plugins :easy_extensions
  
  included do
    def empe_cashflow_between(start_date, end_date, scope, attr, options = {})
      scope.where("#{attr} >= ? AND #{attr} <= ?", start_date, end_date)
    end

    def empe_cashflow_other_revenues_between(start_date, end_date, options = {})
      scope = self.easy_money.other_revenues_scope.where(Project.allowed_to_condition(User.current, :easy_money_cash_flow_history, project: self, with_subprojects: true))
      @empe_other_revenues ||= {}
      @empe_other_revenues["#{start_date}#{end_date}"] ||= self.empe_cashflow_between(start_date, end_date, scope, 'spent_on', options).select([empe_price_column(:price1, options), empe_price_column(:price2, options)]).to_a
    end

    def empe_cashflow_other_expenses_between(start_date, end_date, options = {})
      scope = self.easy_money.other_expenses_scope.where(Project.allowed_to_condition(User.current, :easy_money_cash_flow_history, project: self, with_subprojects: true))
      @empe_other_expenses ||= {}
      @empe_other_expenses["#{start_date}#{end_date}"] ||= self.empe_cashflow_between(start_date, end_date, scope, 'spent_on', options).select([empe_price_column(:price1, options), empe_price_column(:price2, options)]).to_a
    end

    def empe_cashflow_expected_revenues_between(start_date, end_date, options = {})
      scope = self.easy_money.expected_revenues_scope.where(Project.allowed_to_condition(User.current, :easy_money_cash_flow_prediction, project: self, with_subprojects: true))
      @empe_expected_revenues ||= {}
      @empe_expected_revenues["#{start_date}#{end_date}"] ||= self.empe_cashflow_between(start_date, end_date, scope, 'spent_on', options).select([empe_price_column(:price1, options), empe_price_column(:price2, options)]).to_a
    end

    def empe_cashflow_expected_expenses_between(start_date, end_date, options = {})
      scope = self.easy_money.expected_expenses_scope.where(Project.allowed_to_condition(User.current, :easy_money_cash_flow_prediction, project: self, with_subprojects: true))
      @empe_expected_expenses ||= {}
      @empe_expected_expenses["#{start_date}#{end_date}"] ||= self.empe_cashflow_between(start_date, end_date, scope, 'spent_on', options).select([empe_price_column(:price1, options), empe_price_column(:price2, options)]).to_a
    end

    def empe_cashflow_time_entry_expenses_between(start_date, end_date, options = {})
      scope = self.easy_money.time_entry_expenses_scope.where(Project.allowed_to_condition(User.current, :easy_money_cash_flow_prediction, project: self, with_subprojects: true))
      empe_cashflow_between(start_date, end_date, scope, "#{TimeEntry.table_name}.spent_on", options).easy_money_time_entries_by_rate_type(self.easy_money.default_rate_type).pluck(empe_price_column(:price, options))
    end

    def empe_cashflow_travel_expenses_between(start_date, end_date, options = {})
      scope = self.easy_money.travel_expenses_scope(additional_permissions: [:easy_money_cash_flow_history])
      self.empe_cashflow_between(start_date, end_date, scope, 'spent_on', options).pluck(empe_price_column(:price1, options))
    end

    def empe_cashflow_travel_costs_between(start_date, end_date, options = {})
      scope = self.easy_money.travel_costs_scope(additional_permissions: [:easy_money_cash_flow_history])
      self.empe_cashflow_between(start_date, end_date, scope, 'spent_on', options).pluck(empe_price_column(:price1, options))
    end

    def empe_cashflow_other_revenues_price1(start_date, end_date, options = {})
      @cfor1 ||= {}
      @cfor1["#{start_date}#{end_date}"] ||= empe_price_sum(self.empe_cashflow_other_revenues_between(start_date, end_date, options), :price1, options)
    end

    def empe_cashflow_other_revenues_price2(start_date, end_date, options = {})
      @cfor2 ||= {}
      @cfor2["#{start_date}#{end_date}"] ||= empe_price_sum(self.empe_cashflow_other_revenues_between(start_date, end_date, options), :price2, options)
    end

    def empe_cashflow_other_expenses_price1(start_date, end_date, options = {})
      @cfoe1 ||= {}
      @cfoe1["#{start_date}#{end_date}"] ||= -empe_price_sum(self.empe_cashflow_other_expenses_between(start_date, end_date, options), :price1, options)
    end

    def empe_cashflow_other_expenses_price2(start_date, end_date, options = {})
      @cfoe2 ||= {}
      @cfoe2["#{start_date}#{end_date}"] ||= -empe_price_sum(self.empe_cashflow_other_expenses_between(start_date, end_date, options), :price2, options)
    end

    def empe_cashflow_expected_revenues_price1(start_date, end_date, options = {})
      @cfer1 ||= {}
      @cfer1["#{start_date}#{end_date}"] ||= empe_price_sum(self.empe_cashflow_expected_revenues_between(start_date, end_date, options), :price1, options)
    end

    def empe_cashflow_expected_revenues_price2(start_date, end_date, options = {})
      @cfer2 ||= {}
      @cfer2["#{start_date}#{end_date}"] ||= empe_price_sum(self.empe_cashflow_expected_revenues_between(start_date, end_date, options), :price2, options)
    end

    def empe_cashflow_expected_expenses_price1(start_date, end_date, options = {})
      @cfee1 ||= {}
      @cfee1["#{start_date}#{end_date}"] ||= -empe_price_sum(self.empe_cashflow_expected_expenses_between(start_date, end_date, options), :price1, options)
    end

    def empe_cashflow_expected_expenses_price2(start_date, end_date, options = {})
      @cfee2 ||= {}
      @cfee2["#{start_date}#{end_date}"] ||= -empe_price_sum(self.empe_cashflow_expected_expenses_between(start_date, end_date, options), :price2, options)
    end

    def empe_cashflow_expected_payroll_expenses_price(start_date, end_date, options = {})
      @cfepe ||= -self.easy_money.sum_expected_payroll_expenses if User.current.allowed_to?(:easy_money_cash_flow_history, self)
      @cfepe ||= 0.0
    end

    def empe_cashflow_time_entry_expenses_price(start_date, end_date, options = {})
      @cftee ||= {}
      @cftee["#{start_date}#{end_date}"] ||= -self.empe_cashflow_time_entry_expenses_between(start_date, end_date, options).sum { |element| element || 0 }
    end

    def empe_cashflow_travel_expenses_price1(start_date, end_date, options = {})
      @cfte1 ||= {}
      @cfte1["#{start_date}#{end_date}"] ||= -self.empe_cashflow_travel_expenses_between(start_date, end_date, options).sum { |element| element || 0 }
    end

    def empe_cashflow_travel_costs_price1(start_date, end_date, options = {})
      @cftc1 ||= {}
      @cftc1["#{start_date}#{end_date}"] ||= -self.empe_cashflow_travel_costs_between(start_date, end_date, options).sum { |element| element || 0 }
    end

    def empe_cashflow_total_costs_price1(start_date, end_date, options = {})
      self.empe_cashflow_other_expenses_price1(start_date, end_date, options) +
          self.empe_cashflow_time_entry_expenses_price(start_date, end_date, options) +
          self.empe_cashflow_travel_expenses_price1(start_date, end_date, options) +
          self.empe_cashflow_travel_costs_price1(start_date, end_date, options)
    end

    def empe_cashflow_prediction_price1(start_date, end_date, options = {})
      self.empe_cashflow_expected_revenues_price1(start_date, end_date, options) +
          self.empe_cashflow_expected_expenses_price1(start_date, end_date, options) +
          self.empe_cashflow_expected_payroll_expenses_price(start_date, end_date, options)
    end

    def empe_cashflow_prediction_price2(start_date, end_date, options = {})
      self.empe_cashflow_expected_revenues_price2(start_date, end_date, options) +
          self.empe_cashflow_expected_expenses_price2(start_date, end_date, options) +
          self.empe_cashflow_expected_payroll_expenses_price(start_date, end_date, options)
    end

    def empe_cashflow_history_price1(start_date, end_date, options = {})
      self.empe_cashflow_other_revenues_price1(start_date, end_date, options) +
          self.empe_cashflow_other_expenses_price1(start_date, end_date, options) +
          self.empe_cashflow_time_entry_expenses_price(start_date, end_date, options) +
          self.empe_cashflow_travel_expenses_price1(start_date, end_date, options) +
          self.empe_cashflow_travel_costs_price1(start_date, end_date, options)
    end

    def empe_cashflow_history_price2(start_date, end_date, options = {})
      self.empe_cashflow_other_revenues_price2(start_date, end_date, options) +
          self.empe_cashflow_other_expenses_price2(start_date, end_date, options) +
          self.empe_cashflow_time_entry_expenses_price(start_date, end_date, options) +
          self.empe_cashflow_travel_expenses_price1(start_date, end_date, options) +
          self.empe_cashflow_travel_costs_price1(start_date, end_date, options)
    end
  end
end
