class EasyMoneyIssue < EasyMoneyEntity

  def easy_money_settings
    @entity.project.easy_money_settings
  end

  def expected_expenses_scope(options = {})
    get_basic_scope_for(EasyMoneyExpectedExpense, :easy_money_show_expected_expense, options)
  end

  def expected_revenues_scope(options = {})
    get_basic_scope_for(EasyMoneyExpectedRevenue, :easy_money_show_expected_revenue, options)
  end

  def other_expenses_scope(options = {})
    get_basic_scope_for(EasyMoneyOtherExpense, :easy_money_show_other_expense, options)
  end

  def other_revenues_scope(options = {})
    get_basic_scope_for(EasyMoneyOtherRevenue, :easy_money_show_other_revenue, options)
  end

  def travel_costs_scope(options = {})
    scope = EasyMoneyTravelCost
    if @entity.project.self_and_descendants.travel_costs_enabled.exists?
      permissions = [:easy_money_show_travel_cost]
      permissions.concat(options[:additional_permissions]) if options[:additional_permissions]
      scope = scope.includes(:project).references(:project).where(create_sql_where(EasyMoneyTravelCost.table_name))
      scope = scope.where(self.travel_allowed_to_condition(permissions))
      scope = merge_scope(scope, options)
      scope
    else
      scope.where('1=0')
    end
  end

  def travel_expenses_scope(options = {})
    scope = EasyMoneyTravelExpense
    if @entity.project.self_and_descendants.travel_expenses_enabled.exists?
      permissions = [:easy_money_show_travel_expense]
      permissions.concat(options[:additional_permissions]) if options[:additional_permissions]
      scope = scope.includes(:project).references(:project).where(create_sql_where(EasyMoneyTravelExpense.table_name))
      scope = scope.where(self.travel_allowed_to_condition(permissions))
      scope = merge_scope(scope, options)
      scope
    else
      scope.none
    end
  end

  def time_entry_scope(options = {})
    sql_where = []
    sql_where << "#{Issue.quoted_table_name}.root_id = #{@entity.root_id} AND #{Issue.quoted_table_name}.lft >= #{@entity.lft} AND #{Issue.quoted_table_name}.rgt <= #{@entity.rgt}"
    sql_where.join(' OR ')

    scope = TimeEntry.joins(:issue).where(sql_where)
    scope = merge_scope(scope, options)
    scope
  end

  def time_entry_expenses_scope(options = {})
    is_ar = Issue.arel_table

    scope = EasyMoneyTimeEntryExpense.joins(:issue)
    scope = scope.where(options[:without_descendants] ? is_ar[:id].eq(@entity.id) : is_ar[:root_id].eq(@entity.root_id).and(is_ar[:lft].gteq(@entity.lft)).and(is_ar[:rgt].lteq(@entity.rgt)) )
    scope = scope_with_permission(scope, :easy_money_show_time_entry_expenses)
    scope = merge_scope(scope, options)
    scope
  end

  def expected_payroll_expenses_scope(options = {})
    get_basic_scope_for(EasyMoneyExpectedPayrollExpense, :easy_money_show_expected_payroll_expense, options)
  end

  def sum_expected_hours(options = {})
    if @entity.project.module_enabled?(:time_tracking)
      @entity.estimated_hours || 0.0
    else
      0.0
    end
  end

  def sum_expected_payroll_expenses(options = {})
    if self.easy_money_settings.expected_payroll_expense_type == 'planned_hours_and_rate'
      if !options[:only_self] && Setting.display_subprojects_issues?
        @entity.self_and_descendants.sum do |entity|
          sum_expected_payroll_expense_for_entity(entity)
        end
      else
        sum_expected_payroll_expense_for_entity(@entity)
      end
    else
      super
    end
  end

  def decorate(view_context)
    @decorate ||= EasyMoneyIssueDecorator.new(self, view_context)
  end

  private

  def sum_expected_payroll_expense_for_entity(entity)
    return 0.0 unless entity.estimated_hours
    if entity.assigned_to_id?
      entity.estimated_hours * EasyMoneyRate.get_unit_rate_for_issue(entity, default_rate_type, easy_currency_code)
    else
      entity.estimated_hours * expected_payroll_expense_rate
    end
  end

  def get_basic_scope_for(entity_class, permission, options = {})
    scope = if options[:only_self]
              entity_class.where(entity_type: 'Issue', entity_id: @entity.id)
            else
              entity_class.joins(create_sql_join(entity_class.table_name))
            end
    scope = scope_with_permission(scope, permission) if permission

    merge_scope(scope, options)
  end

  def scope_with_permission(scope, permission)
    scope.joins(:project).where(Project.allowed_to_condition(User.current, permission,
                                                             project: @entity.project,
                                                             with_subprojects: true))
  end

  def create_sql_join(entity_table_name)
    "INNER JOIN #{Issue.quoted_table_name} i ON i.id = #{entity_table_name}.entity_id AND #{entity_table_name}.entity_type = 'Issue' AND i.root_id = #{@entity.root_id} AND i.lft >= #{@entity.lft} AND i.rgt <= #{@entity.rgt}"
  end

  def create_sql_where(entity_table_name)
    sql_where = []
    sql_where << "EXISTS (SELECT i.id FROM #{Issue.table_name} i WHERE i.id = #{entity_table_name}.entity_id AND #{entity_table_name}.entity_type = 'Issue' AND i.root_id = #{@entity.root_id} AND i.lft >= #{@entity.lft} AND i.rgt <= #{@entity.rgt})"
    sql_where.join(' OR ')
  end

end
