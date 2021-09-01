class EasyMoneyCrmCasesBudgetController < ApplicationController
  include EasyMoneyEntitiesBudgetControllerConcern

  def entity_money_query
    EasyMoneyCrmCasesBudgetQuery
  end

  def required_project_module
    'easy_crm'
  end
end
