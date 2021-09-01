if Redmine::Plugin.installed?(:easy_crm)
  class EasyMoneyCrmCasesBudgetQuery < EasyCrmCaseQuery
    include EasyMoneyEntityBudgetQueryConcern

    def decorator_class
      EasyMoney::CrmCaseBudgetQueryDecorator
    end

    def default_list_columns
      super.presence || %w[project name price]
    end

    def default_group_label
      l(:label_filter_group_easy_crm_case_query)
    end

    def project_scope
      project ? nil : Project.easy_money_setting_condition(Project.all, 'use_easy_money_for_easy_crm_cases').has_module(:easy_money)
    end

    def additional_scope
      @additional_scope ||= project_scope
    end

  end
end
