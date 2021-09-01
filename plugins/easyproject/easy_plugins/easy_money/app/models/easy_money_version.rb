class EasyMoneyVersion < EasyMoneyEntity

  def easy_money_settings
    @entity.project.easy_money_settings
  end

  def expected_hours(options={})
    @entity.estimated_hours
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

  def time_entry_scope(options={})
    scope = TimeEntry.joins(:issue => :fixed_version).where("#{Issue.quoted_table_name}.fixed_version_id = #{@entity.id}")
    scope = merge_scope(scope, options)
    scope
  end

  def time_entry_expenses_scope(options={})
    sql_where = []
    sql_where << "EXISTS (SELECT t.id FROM #{TimeEntry.table_name} t INNER JOIN #{Issue.table_name} i ON i.id = t.issue_id WHERE t.id = #{EasyMoneyTimeEntryExpense.table_name}.time_entry_id AND i.fixed_version_id = #{@entity.id})"
    sql_where.join(' OR ')

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

  def sum_expected_hours(options={})
    if @entity.project.module_enabled?(:time_tracking)
      @entity.estimated_hours
    else
      0.0
    end
  end

  def sum_expected_payroll_expenses(options={})
    if self.easy_money_settings.expected_payroll_expense_type == 'planned_hours_and_rate'
      compute_childs = options.key?(:only_self) ? options[:only_self] != true : self.easy_money_settings.include_childs?
      rate_type = default_rate_type

      planned_payrolls = @entity.sum_of_issues_estimated_hours_scope(!compute_childs).where("#{Issue.table_name}.assigned_to_id IS NULL").sum(:estimated_hours) * expected_payroll_expense_rate

      @entity.sum_of_issues_estimated_hours_scope.where("#{Issue.table_name}.assigned_to_id IS NOT NULL").each do |issue|
        planned_payrolls += issue.estimated_hours * EasyMoneyRate.get_unit_rate_for_issue(issue, rate_type, easy_currency_code)
      end

      planned_payrolls
    else
      super
    end
  end

  private

  def create_sql_where(entity_table_name)
    "#{entity_table_name}.entity_type = 'Version' AND #{entity_table_name}.entity_id = #{@entity.id}"
  end

end
