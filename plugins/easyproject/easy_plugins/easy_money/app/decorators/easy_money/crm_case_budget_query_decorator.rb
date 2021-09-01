module EasyMoney
  class CrmCaseBudgetQueryDecorator < IssueBudgetQueryDecorator

    def self.format_html_entity_name
      'easy_money_crm_case_budget'
    end

    def self.currency_options
      EasyCrmCase.currency_options
    end

  end
end
