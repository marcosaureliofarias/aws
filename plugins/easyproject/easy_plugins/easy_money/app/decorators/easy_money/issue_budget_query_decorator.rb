module EasyMoney
  class IssueBudgetQueryDecorator < EasyQueryDecorator
    def self.format_html_entity_name
      'easy_money_issue_budget'
    end

    def planned_incomes_with_vat
      easy_money.sum_expected_revenues(:price1)
    end

    def planned_incomes_without_vat
      easy_money.sum_expected_revenues(:price2)
    end

    def planned_expenses_with_vat
      easy_money.sum_expected_expenses(:price1)
    end

    def planned_expenses_without_vat
      easy_money.sum_expected_expenses(:price2)
    end

    def planned_personal_costs
      easy_money.sum_expected_payroll_expenses
    end

    def planned_total_expenses_with_vat
      easy_money.sum_all_expected_expenses(:price1)
    end

    def planned_total_expenses_without_vat
      easy_money.sum_all_expected_expenses(:price2)
    end

    def planned_profit_with_vat
      easy_money.expected_profit(:price1)
    end

    def planned_profit_without_vat
      easy_money.expected_profit(:price2)
    end

    def actual_incomes_with_vat
      easy_money.sum_other_revenues(:price1)
    end

    def actual_incomes_without_vat
      easy_money.sum_other_revenues(:price2)
    end

    def actual_expenses_with_vat
      easy_money.sum_other_expenses(:price1)
    end

    def actual_expenses_without_vat
      easy_money.sum_other_expenses(:price2)
    end

    def actual_personal_costs
      easy_money.sum_time_entry_expenses
    end

    def actual_total_expenses_with_vat
      easy_money.sum_all_other_and_travel_expenses(:price1)
    end

    def actual_total_expenses_without_vat
      easy_money.sum_all_other_and_travel_expenses(:price2)
    end

    def actual_profit_with_vat
      easy_money.other_profit(:price1)
    end

    def actual_profit_without_vat
      easy_money.other_profit(:price2)
    end

    def profit_margin
      easy_money.gross_margin(:price1)
    end

    def net_margin
      easy_money.net_margin(:price1)
    end

    def easy_currency_code
      query.easy_currency_code.presence || model.project.easy_currency_code
    end

    def easy_money
      model.easy_money(easy_currency_code)
    end
  end
end
