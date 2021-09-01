class EasyMoneyEasyCrmCase < EasyMoneyEntity

  def easy_money_settings
    @entity.project.easy_money_settings
  end

  def expected_hours(options={})
    0.0
  end

  def expected_expenses_scope(options={})
    scope = EasyMoneyExpectedExpense.where(create_sql_where(EasyMoneyExpectedExpense.table_name))
    scope = scope.includes(:project).references(:project).where(Project.allowed_to_condition(User.current, :easy_money_show_expected_expense, :project => @entity.project, :with_subprojects => true))
    scope = merge_scope(scope, options)
    scope
  end

  def expected_revenues_scope(options={})
    scope = EasyMoneyExpectedRevenue.where(create_sql_where(EasyMoneyExpectedRevenue.table_name))
    scope = scope.includes(:project).references(:project).where(Project.allowed_to_condition(User.current, :easy_money_show_expected_revenue, :project => @entity.project, :with_subprojects => true))
    scope = merge_scope(scope, options)
    scope
  end

  def other_expenses_scope(options={})
    scope = EasyMoneyOtherExpense.where(create_sql_where(EasyMoneyOtherExpense.table_name))
    scope = scope.includes(:project).references(:project).where(Project.allowed_to_condition(User.current, :easy_money_show_other_expense, :project => @entity.project, :with_subprojects => true))
    scope = merge_scope(scope, options)
    scope
  end

  def other_revenues_scope(options={})
    scope = EasyMoneyOtherRevenue.where(create_sql_where(EasyMoneyOtherRevenue.table_name))
    scope = scope.includes(:project).references(:project).where(Project.allowed_to_condition(User.current, :easy_money_show_other_revenue, :project => @entity.project, :with_subprojects => true))
    scope = merge_scope(scope, options)
    scope
  end

  def time_entry_scope(options={})
    sql_where = "EXISTS (SELECT i.id FROM #{EasyCrmCase.table_name} i WHERE i.id = #{TimeEntry.table_name}.entity_id AND #{TimeEntry.table_name}.entity_id = #{@entity.id} AND #{TimeEntry.table_name}.entity_type = 'EasyCrmCase')"

    scope = TimeEntry.where(sql_where)
    scope = merge_scope(scope, options)
    scope
  end

  def time_entry_expenses_scope(options={})
    sql_where = "EXISTS (SELECT t.id FROM #{TimeEntry.table_name} t INNER JOIN #{EasyCrmCase.table_name} i ON i.id = t.entity_id AND t.entity_type = 'EasyCrmCase' WHERE t.id = #{EasyMoneyTimeEntryExpense.table_name}.time_entry_id AND t.entity_id = #{@entity.id})"

    scope = EasyMoneyTimeEntryExpense.where(sql_where)
    scope = scope.includes(:project).references(:project).where(Project.allowed_to_condition(User.current, :easy_money_show_time_entry_expenses, :project => @entity.project, :with_subprojects => true))
    scope = merge_scope(scope, options)
    scope
  end

  def expected_payroll_expenses_scope(options={})
    scope = EasyMoneyExpectedPayrollExpense.where(create_sql_where(EasyMoneyExpectedPayrollExpense.table_name))
    scope = scope.includes(:project).references(:project).where(Project.allowed_to_condition(User.current, :easy_money_show_expected_payroll_expense, :project => @entity.project, :with_subprojects => true))
    scope = merge_scope(scope, options)
    scope
  end

  def travel_costs_scope(options={})
    scope = EasyMoneyTravelCost
    if @entity.project.self_and_descendants.travel_costs_enabled.exists?
      permissions = [:easy_money_show_travel_cost]
      permissions.concat(options[:additional_permissions]) if options[:additional_permissions]
      scope = scope.includes(:project).references(:project).where(create_sql_where(EasyMoneyTravelCost.table_name))
      scope = scope.where(self.travel_allowed_to_condition(permissions))
      scope = merge_scope(scope, options)
      scope
    else
      scope = scope.where('1=0')
    end
  end

  def travel_expenses_scope(options={})
    scope = EasyMoneyTravelExpense
    if @entity.project.self_and_descendants.travel_expenses_enabled.exists?
      permissions = [:easy_money_show_travel_expense]
      permissions.concat(options[:additional_permissions]) if options[:additional_permissions]
      scope = scope.includes(:project).references(:project).where(create_sql_where(EasyMoneyTravelExpense.table_name))
      scope = scope.where(self.travel_allowed_to_condition(permissions))
      scope = merge_scope(scope, options)
      scope
    else
      scope = scope.where('1=0')
    end
  end

  def sum_expected_hours(options={})
    0.0
  end

  def sum_expected_payroll_expenses(options={})
    super
  end

  private

  def create_sql_where(entity_table_name)
    "#{entity_table_name}.entity_type = 'EasyCrmCase' AND #{entity_table_name}.entity_id = #{@entity.id}"
  end

end
