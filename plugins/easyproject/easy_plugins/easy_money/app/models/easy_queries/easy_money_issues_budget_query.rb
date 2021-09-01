class EasyMoneyIssuesBudgetQuery < EasyIssueQuery
  include EasyMoneyEntityBudgetQueryConcern

  def default_list_columns
    super.presence || %w[project subject status]
  end

  def default_group_label
    l(:label_filter_group_easy_issue_query)
  end

  def project_scope
    scope = super

    unless project
      scope = Project.easy_money_setting_condition(scope, 'use_easy_money_for_issues')
    end

    scope.has_module(:easy_money)
  end

  def entity_easy_query_path(options)
    if (project = options.delete(:project))
      project_easy_money_project_issues_budget_path(project, options)
    else
      easy_money_issues_budget_path(options)
    end
  end

end
