class EasyMoneyEntity

  attr_reader :entity, :easy_currency_code

  def initialize(entity, easy_currency_code)
    raise TypeError, 'Cannot initialize this class. Use inherited childs instead.' if self.class.name == 'EasyMoneyEntity'
    raise ArgumentError, 'Entity cannot be null.' if entity.nil?

    @entity = entity
    @easy_currency_code = easy_currency_code || EasyCurrency.default_code
  end

  def self.allowed_entities(project = nil)
    allowed_entities = %w(Project)
    if project
      if project.module_enabled?('issue_tracking')
        allowed_entities << 'Issue' if project.easy_money_settings.use_easy_money_for_issues?
        allowed_entities << 'Version' if project.easy_money_settings.use_easy_money_for_versions?
      end
    else
      allowed_entities.concat(%w(Issue Version))
    end
    allowed_entities
  end

  def self.compute_price1(project, price2)
    vat = project.easy_money_settings.vat.to_f
    price1 = (price2 * (vat + 100)) / 100
    price1
  end

  def self.compute_price2(project, price1)
    vat = project.easy_money_settings.vat.to_f
    price2 = (price1.to_f * 100) / (vat + 100)
    price2
  end

  def easy_money_settings
    @entity.easy_money_settings || @entity.parent.try(:easy_money_settings)
  end

  def travel_allowed_to_condition(permissions)
    permissions.map { |p| Project.allowed_to_condition(User.current, p, :project => @entity.project, :with_subprojects => true) }.join(' AND ')
  end

  def default_price_type
    @default_price_type ||= if self.easy_money_settings && self.easy_money_settings.expected_count_price
                               self.easy_money_settings.expected_count_price.to_sym
                            else
                              :price1
                            end
  end

  def default_rate_type
    @default_rate_type ||= if self.easy_money_settings && self.easy_money_settings.expected_rate_type
         EasyMoneyRateType.active.where(:name => self.easy_money_settings.expected_rate_type).first
      end
    @default_rate_type ||= EasyMoneyRateType.active.order(:position).first
  end

  def expected_expenses_scope(options={})
    raise NotImplementedError, 'You have to override \'expected_expenses_scope\' method!'
  end

  def expected_revenues_scope(options={})
    raise NotImplementedError, 'You have to override \'expected_revenues_scope\' method!'
  end

  def other_expenses_scope(options={})
    raise NotImplementedError, 'You have to override \'other_expenses_scope\' method!'
  end

  def other_revenues_scope(options={})
    raise NotImplementedError, 'You have to override \'other_revenues_scope\' method!'
  end

  def time_entry_scope(options={})
    raise NotImplementedError, 'You have to override \'time_entry_scope\' method!'
  end

  def time_entry_expenses_scope(options={})
    raise NotImplementedError, 'You have to override \'time_entry_expenses_scope\' method!'
  end

  def expected_payroll_expenses_scope(options={})
    raise NotImplementedError, 'You have to override \'expected_payroll_expenses_scope\' method!'
  end

  #
  # EXPECTED HOURS
  #
  def sum_expected_hours(options={})
    0.0
  end

  #
  # EXPECTED PAYROLL EXPENSES
  #

  def expected_payroll_expense_rate
    @expected_payroll_expense_rate ||= easy_money_settings.expected_payroll_expense_rate(easy_currency_code)
  end

  def sum_expected_payroll_expenses(options={})
    case self.easy_money_settings.expected_payroll_expense_type
    when 'amount'
      expected_payroll_expenses_scope(options).sum(price_column(:price)) || 0.0
    when 'hours'
      ((@entity.expected_hours && @entity.expected_hours.hours.to_f) || 0.0) * expected_payroll_expense_rate
    when 'estimated_hours'
      self.sum_expected_hours(options) * expected_payroll_expense_rate
    when 'planned_hours_and_rate'
      0.0 # computed in inherited class
    else
      0.0
    end
  end

  def sum_expected_payroll_expenses_on_entity(options={})
    case self.easy_money_settings.expected_payroll_expense_type
    when 'amount'
      @entity.expected_payroll_expenses.nil? ? 0.0 : (@entity.expected_payroll_expenses.price(easy_currency_code) || 0.0)
    when 'hours'
      ((@entity.expected_hours && @entity.expected_hours.hours.to_f) || 0.0) * expected_payroll_expense_rate
    when 'estimated_hours'
      self.sum_expected_hours(options) * expected_payroll_expense_rate
    when 'planned_hours_and_rate'
      0.0 # computed in inherited class
    else
      0.0
    end
  end

  #
  # EXPECTED EXPENSES
  #
  def sum_expected_expenses(price_type=nil, options={})
    price_type ||= self.default_price_type
    expected_expenses_scope(options).sum(price_column(price_type)) || 0.0
  end

  def sum_expected_expenses_on_entity(price_type=nil, options={})
    price_type ||= self.default_price_type
    @entity.expected_expenses.sum(price_column(price_type)) || 0.0
  end

  #
  # EXPECTED REVENUES
  #
  def sum_expected_revenues(price_type=nil, options={})
    price_type ||= self.default_price_type
    expected_revenues_scope(options).sum(price_column(price_type)) || 0.0
  end

  def sum_expected_revenues_on_entity(price_type=nil, options={})
    price_type ||= self.default_price_type
    @entity.expected_revenues.sum(price_column(price_type)) || 0.0
  end

  #
  # OTHER EXPENSES
  #
  def sum_other_expenses(price_type=nil, options={})
    price_type ||= self.default_price_type
    other_expenses_scope(options).sum(price_column(price_type)) || 0.0
  end

  def sum_other_expenses_on_entity(price_type=nil, options={})
    price_type ||= self.default_price_type
    @entity.other_expenses.sum(price_column(price_type)) || 0.0
  end

  #
  # OTHER REVENUES
  #
  def sum_other_revenues(price_type=nil, options={})
    price_type ||= self.default_price_type
    other_revenues_scope(options).sum(price_column(price_type)) || 0.0
  end

  def sum_other_revenues_on_entity(price_type=nil, options={})
    price_type ||= self.default_price_type
    @entity.other_revenues.sum(price_column(price_type)) || 0.0
  end

  #
  # TRAVEL COSTS
  #
  def sum_travel_costs(price_type=nil, options={})
    travel_costs_scope(options).sum(price_column(:price1)) || 0.0
  end

  def sum_travel_costs_on_entity(price_type=nil, options={})
    @entity.travel_costs.sum(price_column(:price1)) || 0.0
  end

  #
  # TRAVEL EXPENSES
  #
  def sum_travel_expenses(price_type=nil, options={})
    travel_expenses_scope(options).sum(price_column(:price1)) || 0.0
  end

  def sum_travel_expenses_on_entity(price_type=nil, options={})
    @entity.travel_expenses.sum(price_column(:price1)) || 0.0
  end

  #
  # TIME ENTRY EXPENSES
  #
  def sum_time_entry_expenses(rate_type=nil, options={})
    rate_type ||= self.default_rate_type
    time_entry_expenses_scope(options).easy_money_time_entries_by_rate_type(rate_type).sum(price_column(:price)) || 0.0
  end

  #
  # TIME ENTRY HOURS
  #
  def sum_time_entry_hours(options={})
    time_entry_scope(options).sum(:hours) || 0.0
  end

  #
  # SUMS
  #
  def sum_all_expected_revenues(price_type=nil, options={})
    price_type ||= self.default_price_type

    sum_expected_revenues(price_type, options)
  end

  def sum_all_expected_expenses(price_type=nil, options={})
    price_type ||= self.default_price_type

    sum_expected_expenses(price_type, options) + sum_expected_payroll_expenses(options)
  end

  def sum_all_other_revenues(price_type=nil, options={})
    sum_other_revenues(price_type, options)
  end

  def sum_all_other_expenses(price_type=nil, rate_type=nil, options={})
    sum_other_expenses(price_type, options) + sum_time_entry_expenses(rate_type, options)
  end

  def sum_all_other_and_travel_expenses(price_type=nil, rate_type=nil, options={})
    price_type ||= self.default_price_type
    rate_type ||= self.default_rate_type

    sum_all_other_expenses(price_type, rate_type, options) + sum_all_travel_expenses(price_type, options) + sum_all_travel_costs(price_type, options)
  end

  def sum_all_travel_expenses(price_type=nil, options={})
    sum_travel_expenses(:price1, options)
  end

  def sum_all_travel_costs(price_type=nil, options={})
    sum_travel_costs(:price1, options)
  end

  def sum_planned_and_other_expenses(options = {})
    expenses_sum_planned = 0
    expenses_sum_other = 0
    project = @entity.project

    if project.self_and_descendants.has_module(:time_tracking).exists?
      if User.current.allowed_to?(:easy_money_show_expected_payroll_expense, project) || User.current.allowed_to?(:easy_money_manage_expected_payroll_expense, project)
        expenses_sum_planned += sum_expected_payroll_expenses(options)
      end
      if User.current.allowed_to?(:easy_money_show_time_entry_expenses, project)
        expenses_sum_other += sum_time_entry_expenses(nil, options)
      end
    end

    if User.current.allowed_to?(:easy_money_show_expected_expense, project) || User.current.allowed_to?(:easy_money_manage_expected_expense, project)
      expenses_sum_planned += sum_expected_expenses(nil, options)
    end
    if User.current.allowed_to?(:easy_money_show_other_expense, project) || User.current.allowed_to?(:easy_money_manage_other_expense, project)
      expenses_sum_other += sum_other_expenses(nil, options)
    end

    if User.current.allowed_to?(:easy_money_show_travel_cost, project) && project.easy_money_settings.use_travel_costs?
      expenses_sum_other += sum_travel_costs(nil, options)
    end

    if User.current.allowed_to?(:easy_money_show_travel_expense, project) && project.easy_money_settings.use_travel_expenses?
      expenses_sum_other += sum_travel_expenses(nil, options)
    end

    [expenses_sum_planned, expenses_sum_other]
  end

  #
  # PROFIT
  #
  def expected_profit(price_type=nil, options={})
    price_type ||= self.default_price_type

    sum_all_expected_revenues(price_type, options) - sum_all_expected_expenses(price_type, options)
  end

  def other_profit(price_type=nil, rate_type=nil, options={})
    sum_all_other_revenues(price_type, options) - sum_all_other_and_travel_expenses(price_type, rate_type, options)
  end

  #
  # AVERAGE HOURLY RATE
  #
  def average_hourly_rate(price_type=nil, options={})
    sor = sum_other_revenues(price_type, options)
    soe = sum_other_expenses(price_type, options)
    steh = self.sum_time_entry_hours(options)

    if steh > 0.0
      (sor - soe) / steh
    else
      0.0
    end
  end

  def gross_margin(price_type=nil, rate_type=nil, options={})
    profit = other_profit(price_type, rate_type, options)
    revenues = sum_all_other_revenues(price_type, options)

    if revenues != 0
      (profit / revenues * 100).round(2)
    else
      0.0
    end
  end

  def net_margin(price_type=nil, rate_type=nil, options={})
    profit_reality = other_profit(price_type, rate_type, options)

    expense_reality = sum_other_expenses(price_type, options)
    incomes_reality = sum_other_revenues(price_type, options)
    profit = incomes_reality - expense_reality

    if profit != 0 && profit_reality != profit
      (profit_reality / profit * 100).round(2)
    else
      0.0
    end
  end

  def cost_ratio
    expenses_planned_sum, expenses_other_sum = sum_planned_and_other_expenses
    if expenses_planned_sum != 0
      (expenses_other_sum / expenses_planned_sum * 100).round(2)
    else
      0.0
    end
  end

  private

  def merge_scope(scope, options={})
    options ||= {}
    options[:scope] ||= {}

    scope = scope.where(options[:scope][:where]) if options[:scope][:where]
    scope = scope.includes(options[:scope][:includes]) if options[:scope][:includes]
    scope = scope.joins(options[:scope][:joins]) if options[:scope][:joins]
    scope = scope.order(options[:scope][:order]) if options[:scope][:order]
    scope = scope.limit(options[:scope][:limit]) if options[:scope][:limit]
    scope = scope.offset(options[:scope][:offset]) if options[:scope][:offset]

    scope
  end

  def price_column(original_column)
    if easy_currency_code && EasyCurrency[easy_currency_code]
      "#{original_column}_#{easy_currency_code}"
    else
      original_column
    end
  end
end
