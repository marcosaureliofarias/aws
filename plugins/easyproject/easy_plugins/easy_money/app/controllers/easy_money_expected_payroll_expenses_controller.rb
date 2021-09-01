class EasyMoneyExpectedPayrollExpensesController < ApplicationController

  menu_item :easy_money

  before_action :find_easy_money_project
  before_action :authorize
  before_action :check_setting_show_expected
  before_action :check_setting_expected_payroll_expense_type, :except => [:inline_expected_payroll_expenses]

  before_action :load_current_easy_currency_code, only: [:inline_edit, :inline_update, :inline_expected_payroll_expenses, :update]

  accept_api_auth  :update

  helper :easy_money
  include EasyMoneyHelper

  def inline_edit
    respond_to do |format|
      format.js
    end
  end

  def inline_update
    create_or_update_expected_payroll_expenses

    respond_to do |format|
      format.js
    end
  end

  def inline_expected_payroll_expenses
    render :partial => 'easy_money_expected_payroll_expenses/inline_expected_payroll_expenses', :locals => {:project => @project, :sum_expected_payroll_expenses => @entity.easy_money.sum_expected_payroll_expenses, :entity => @entity }
  end

  def update
    create_or_update_expected_payroll_expenses
    respond_to do |format|
      format.api { render_api_ok }
    end
  end

  private
  def create_or_update_expected_payroll_expenses
    expected_payroll_expenses = @entity.expected_payroll_expenses
    if expected_payroll_expenses
      expected_payroll_expenses.update(expected_payroll_expenses_params)
    else
      @entity.create_expected_payroll_expenses(expected_payroll_expenses_params)
    end
  end

  def expected_payroll_expenses_params
    params.require(:expected_payroll_expenses).permit(:price, :easy_currency_code)
  end

  def check_setting_show_expected
    render_404 unless @project.easy_money_settings.show_expected?
  end

  def check_setting_expected_payroll_expense_type
    render_404 if @project.easy_money_settings.expected_payroll_expense_type == 'hours'
  end
end
