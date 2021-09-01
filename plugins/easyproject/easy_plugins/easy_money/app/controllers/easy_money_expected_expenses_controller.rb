class EasyMoneyExpectedExpensesController < EasyMoneyBaseItemsController

  menu_item :easy_money

  before_action :check_setting_show_expected
  before_action :check_setting_expenses_type, :only => [:new, :create]

  def inline_update
    entity = @entity.expected_expenses.first || @entity.expected_expenses.new(:name => l(:label_easy_money_new_expense_text), :description => l(:label_easy_money_new_expense_description), :spent_on => Date.current)
    super(entity)
  end

  private

  def check_setting_expenses_type
    render_404 if @project && @project.easy_money_settings.expenses_type == 'sum' && @project.expected_expenses.size > 0
  end

  def easy_money_entity_class
    EasyMoneyExpectedExpense
  end

  def easy_money_entity_relation
    'expected_expenses'
  end

  def easy_money_query
    EasyMoneyExpectedExpenseQuery
  end

end
