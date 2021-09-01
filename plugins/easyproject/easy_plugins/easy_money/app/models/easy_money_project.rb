class EasyMoneyProject < EasyMoneyEntity

  def expected_expenses_scope(options={})
    scope = EasyMoneyExpectedExpense.where(create_sql_where(EasyMoneyExpectedExpense.table_name, options))
    scope = scope.includes(:project).references(:project).where(Project.allowed_to_condition(User.current, :easy_money_show_expected_expense, :project => @entity, :with_subprojects => true))
    scope = merge_scope(scope, options)
    scope
  end

  def expected_revenues_scope(options={})
    scope = EasyMoneyExpectedRevenue.where(create_sql_where(EasyMoneyExpectedRevenue.table_name, options))
    scope = scope.includes(:project).references(:project).where(Project.allowed_to_condition(User.current, :easy_money_show_expected_revenue, :project => @entity, :with_subprojects => true))
    scope = merge_scope(scope, options)
    scope
  end

  def other_expenses_scope(options={})
    scope = EasyMoneyOtherExpense.where(create_sql_where(EasyMoneyOtherExpense.table_name, options))
    scope = scope.includes(:project).references(:project).where(Project.allowed_to_condition(User.current, :easy_money_show_other_expense, :project => @entity, :with_subprojects => true))
    scope = merge_scope(scope, options)
    scope
  end

  def other_revenues_scope(options={})
    scope = EasyMoneyOtherRevenue.where(create_sql_where(EasyMoneyOtherRevenue.table_name, options))
    scope = scope.includes(:project).references(:project).where(Project.allowed_to_condition(User.current, :easy_money_show_other_revenue, :project => @entity, :with_subprojects => true))
    scope = merge_scope(scope, options)
    scope
  end

  def travel_costs_scope(options={})
    scope = EasyMoneyTravelCost
    if @entity.self_and_descendants.travel_costs_enabled.exists?
      permissions = [:easy_money_show_travel_cost]
      permissions.concat(options[:additional_permissions]) if options[:additional_permissions]
      scope = scope.includes(:project).references(:project).where(create_sql_where(EasyMoneyTravelCost.table_name, options))
      scope = scope.where(self.travel_allowed_to_condition(permissions))
      scope = merge_scope(scope, options)
      scope
    else
      scope = scope.where('1=0')
    end
  end

  def travel_expenses_scope(options={})
    scope = EasyMoneyTravelExpense
    if @entity.self_and_descendants.travel_expenses_enabled.exists?
      permissions = [:easy_money_show_travel_expense]
      permissions.concat(options[:additional_permissions]) if options[:additional_permissions]
      scope = scope.includes(:project).references(:project).where(create_sql_where(EasyMoneyTravelExpense.table_name, options))
      scope = scope.where(self.travel_allowed_to_condition(permissions))
      scope = merge_scope(scope, options)
      scope
    else
      scope = scope.where('1=0')
    end
  end

  def time_entry_scope(options={})
    compute_childs = options.key?(:only_self) ? options[:only_self] != true : self.easy_money_settings.include_childs?
    if compute_childs
      sql_where = "EXISTS (
SELECT p.id
FROM #{Project.table_name} p
WHERE p.id = #{TimeEntry.table_name}.project_id
AND p.lft >= #{@entity.lft} AND p.rgt <= #{@entity.rgt}
AND EXISTS (SELECT em.id FROM #{EnabledModule.table_name} em WHERE em.project_id = p.id AND em.name = 'easy_money')
AND p.status <> #{Project::STATUS_ARCHIVED})"
    else
      sql_where = "EXISTS (
SELECT p.id
FROM #{Project.table_name} p
WHERE p.id = #{TimeEntry.table_name}.project_id
AND p.id = #{@entity.id}
AND EXISTS (SELECT em.id FROM #{EnabledModule.table_name} em WHERE em.project_id = p.id AND em.name = 'easy_money')
AND p.status <> #{Project::STATUS_ARCHIVED})"
    end

    scope = TimeEntry.where(sql_where)
    scope = merge_scope(scope, options)
    scope
  end

  def time_entry_expenses_scope(options={})
    sql_where = 'EXISTS ('

    compute_childs = options.key?(:only_self) ? options[:only_self] != true : self.easy_money_settings.include_childs?
    if compute_childs
      sql_where << "
SELECT t.id
FROM #{TimeEntry.table_name} t
INNER JOIN #{Project.table_name} p ON p.id = t.project_id
WHERE t.id = #{EasyMoneyTimeEntryExpense.table_name}.time_entry_id
AND p.lft >= #{@entity.lft} AND p.rgt <= #{@entity.rgt}
AND EXISTS (SELECT em.id FROM #{EnabledModule.table_name} em WHERE em.project_id = p.id AND em.name = 'easy_money')
AND p.status <> #{Project::STATUS_ARCHIVED}"
    else
      sql_where << "
SELECT t.id
FROM #{TimeEntry.table_name} t
INNER JOIN #{Project.table_name} p ON p.id = t.project_id
WHERE t.id = #{EasyMoneyTimeEntryExpense.table_name}.time_entry_id
AND p.id = #{@entity.id}
AND EXISTS (SELECT em.id FROM #{EnabledModule.table_name} em WHERE em.project_id = p.id AND em.name = 'easy_money')
AND p.status <> #{Project::STATUS_ARCHIVED}"
    end

    if (period_from = options.delete(:period_from)) && (period_to = options.delete(:period_to))
      sql_where << " AND t.spent_on BETWEEN '#{Project.connection.quoted_date(period_from)}' AND '#{Project.connection.quoted_date(period_to)}'"
    end

    sql_where << ')'

    scope = EasyMoneyTimeEntryExpense.where(sql_where)
    scope = scope.includes(:project).references(:project).where(Project.allowed_to_condition(User.current, :easy_money_show_time_entry_expenses, :project => @entity, :with_subprojects => true))
    scope = merge_scope(scope, options)

    scope
  end

  def expected_payroll_expenses_scope(options={})
    scope = EasyMoneyExpectedPayrollExpense.where(create_sql_where(EasyMoneyExpectedPayrollExpense.table_name))
    scope = scope.includes(:project).references(:project).where(Project.allowed_to_condition(User.current, :easy_money_show_expected_payroll_expense, :project => @entity, :with_subprojects => true))
    scope = merge_scope(scope, options)
    scope
  end

  def sum_expected_hours(options={})
    compute_childs = options.key?(:only_self) ? options[:only_self] != true : self.easy_money_settings.include_childs?
    if self.easy_money_settings.expected_payroll_expense_type == 'estimated_hours'
      if @entity.module_enabled?(:issue_tracking) && @entity.module_enabled?(:time_tracking)
        @entity.sum_of_issues_estimated_hours(!compute_childs)
      else
        0.0
      end
    elsif self.easy_money_settings.expected_payroll_expense_type == 'planned_hours_and_rate'
      @entity.sum_of_issues_estimated_hours(!compute_childs)
    else
      @entity.expected_hours.nil? ? 0.0 : @entity.expected_hours.hours
    end
  end

  def sum_expected_payroll_expenses(options={})
    if self.easy_money_settings.expected_payroll_expense_type == 'planned_hours_and_rate'
      rate_type = default_rate_type

      @entity.sum_of_issues_estimated_hours_scope.to_a.sum do |issue|
        if issue.assigned_to_id?
          issue.estimated_hours * EasyMoneyRate.get_unit_rate_for_issue(issue, rate_type, easy_currency_code)
        else
          issue.estimated_hours * expected_payroll_expense_rate
        end
      end
    else
      super
    end
  end

  def sum_all_expected_expenses(price_type=nil, options={})
    price_type ||= self.default_price_type

    if @entity.self_and_descendants.has_module(:time_tracking).size > 0
      sum_expected_expenses(price_type, options) + sum_expected_payroll_expenses(options)
    else
      sum_expected_expenses(price_type, options)
    end

  end

  def sum_all_other_expenses(price_type=nil, rate_type=nil, options={})
    price_type ||= self.default_price_type
    rate_type ||= self.default_rate_type

    if @entity.self_and_descendants.has_module(:time_tracking).size > 0
      sum_other_expenses(price_type, options) + sum_time_entry_expenses(rate_type, options)
    else
      sum_other_expenses(price_type, options)
    end
  end

  private

  def create_sql_where(entity_table_name, options={})
    options ||= {}
    compute_childs = options.key?(:only_self) ? options[:only_self] != true : self.easy_money_settings.include_childs?
    sql_where = []

    if compute_childs
      sql_where << "EXISTS (
SELECT p.id
FROM #{Project.table_name} p
WHERE p.id = #{entity_table_name}.entity_id
AND #{entity_table_name}.entity_type = 'Project' AND p.lft >= #{@entity.lft} AND p.rgt <= #{@entity.rgt}
AND EXISTS (SELECT em.id FROM #{EnabledModule.table_name} em WHERE em.project_id = p.id AND em.name = 'easy_money')
AND p.status <> #{Project::STATUS_ARCHIVED})"
      sql_where << "EXISTS (
SELECT i.id
FROM #{Issue.table_name} i
INNER JOIN #{Project.table_name} p ON p.id = i.project_id
WHERE i.id = #{entity_table_name}.entity_id
AND #{entity_table_name}.entity_type = 'Issue' AND p.lft >= #{@entity.lft} AND p.rgt <= #{@entity.rgt}
AND EXISTS (SELECT em.id FROM #{EnabledModule.table_name} em WHERE em.project_id = p.id AND em.name = 'easy_money')
AND p.status <> #{Project::STATUS_ARCHIVED})"
      sql_where << "EXISTS (
SELECT v.id
FROM #{Version.table_name} v
INNER JOIN #{Project.table_name} p ON p.id = v.project_id
WHERE v.id = #{entity_table_name}.entity_id
AND #{entity_table_name}.entity_type = 'Version' AND p.lft >= #{@entity.lft} AND p.rgt <= #{@entity.rgt}
AND EXISTS (SELECT em.id FROM #{EnabledModule.table_name} em WHERE em.project_id = p.id AND em.name = 'easy_money')
AND p.status <> #{Project::STATUS_ARCHIVED})"
    else
      sql_where << "EXISTS (
SELECT p.id
FROM #{Project.table_name} p
WHERE p.id = #{entity_table_name}.entity_id
AND #{entity_table_name}.entity_type = 'Project' AND p.id = #{@entity.id}
AND EXISTS (SELECT em.id FROM #{EnabledModule.table_name} em WHERE em.project_id = p.id AND em.name = 'easy_money')
AND p.status <> #{Project::STATUS_ARCHIVED})"
      sql_where << "EXISTS (
SELECT i.id
FROM #{Issue.table_name} i
INNER JOIN #{Project.table_name} p ON p.id = i.project_id
WHERE i.id = #{entity_table_name}.entity_id
AND #{entity_table_name}.entity_type = 'Issue' AND p.id = #{@entity.id}
AND EXISTS (SELECT em.id FROM #{EnabledModule.table_name} em WHERE em.project_id = p.id AND em.name = 'easy_money')
AND p.status <> #{Project::STATUS_ARCHIVED})"
      sql_where << "EXISTS (
SELECT v.id
FROM #{Version.table_name} v
INNER JOIN #{Project.table_name} p ON p.id = v.project_id
WHERE v.id = #{entity_table_name}.entity_id
AND #{entity_table_name}.entity_type = 'Version' AND v.project_id = #{@entity.id}
AND EXISTS (SELECT em.id FROM #{EnabledModule.table_name} em WHERE em.project_id = p.id AND em.name = 'easy_money')
AND p.status <> #{Project::STATUS_ARCHIVED})"
    end

    Redmine::Hook.call_hook(:model_project_create_sql_where, entity_table_name: entity_table_name, entity: @entity, sql_where: sql_where, compute_childs: compute_childs)

    sql_where.join(' OR ')
  end

end
