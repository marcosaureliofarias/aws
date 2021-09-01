class EasyMoneyIssuesBudgetController < ApplicationController
  include EasyMoneyEntitiesBudgetControllerConcern

  def entity_money_query
    EasyMoneyIssuesBudgetQuery
  end

  def required_project_module
    'issue_tracking'
  end

end
