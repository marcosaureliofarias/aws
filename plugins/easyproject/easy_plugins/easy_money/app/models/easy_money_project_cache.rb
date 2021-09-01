class EasyMoneyProjectCache < ActiveRecord::Base

  belongs_to :project

  validates :project_id, presence: true
  validates :easy_currency_code, uniqueness: {scope: :project_id}, on: :create

  def self.css_icon
    'icon icon-money easy-money'
  end

  def parent_project
    @parent_project ||= self.project.parent_project if self.project
  end

  def main_project
    @main_project ||= self.project.main_project if self.project
  end

  def author
    @author ||= self.project.author if self.project
  end

  def self.update_from_project!(project, options = {})
    options[:sum_of_estimated_hours] = project.sum_estimated_hours
    options[:sum_of_timeentries] = project.sum_of_timeentries
    project.easy_money_project_caches.destroy_all

    if EasyCurrency.activated.any?
      EasyCurrency.activated.pluck(:iso_code).each do |easy_currency_code|
        update_by_currency(project, options, easy_currency_code)
      end
    else
      update_by_currency(project, options)
    end
  end

  def self.update_by_currency(project, options = {}, easy_currency_code = nil)
    project_cache = project.easy_money_project_caches.where(easy_currency_code: easy_currency_code).build

    if project.module_enabled?(:easy_money)
      easy_money = EasyMoneyProject.new(project, easy_currency_code)
      project_cache.update_from_easy_money easy_money, options

      project_cache.sum_of_estimated_hours = options[:sum_of_estimated_hours] if options[:sum_of_estimated_hours]
      project_cache.sum_of_timeentries = options[:sum_of_timeentries] if options[:sum_of_timeentries]
    end

    columns.each do |column|
      if [:float, :decimal].include?(column.type) && project_cache.attributes[column.name].nil?
        project_cache.public_send "#{column.name}=", 0.0
      end
    end

    project_cache.save!
  end

  def update_from_easy_money(easy_money, options = {})
    options[:only_self] = true unless options.key?(:only_self)

    rate_type_internal = EasyMoneyRateType.rate_type_cache(:name => 'internal')
    rate_type_external = EasyMoneyRateType.rate_type_cache(:name => 'external')

    self.sum_of_expected_hours                = easy_money.sum_expected_hours(options)
    self.sum_of_expected_payroll_expenses     = easy_money.sum_expected_payroll_expenses(options)

    self.sum_of_expected_expenses_price_1     = easy_money.sum_expected_expenses(:price1, options)
    self.sum_of_expected_revenues_price_1     = easy_money.sum_expected_revenues(:price1, options)
    self.sum_of_other_expenses_price_1        = easy_money.sum_other_expenses(:price1, options)
    self.sum_of_other_revenues_price_1        = easy_money.sum_other_revenues(:price1, options)

    self.sum_of_expected_expenses_price_2     = easy_money.sum_expected_expenses(:price2, options)
    self.sum_of_expected_revenues_price_2     = easy_money.sum_expected_revenues(:price2, options)
    self.sum_of_other_expenses_price_2        = easy_money.sum_other_expenses(:price2, options)
    self.sum_of_other_revenues_price_2        = easy_money.sum_other_revenues(:price2, options)

    self.sum_of_all_expected_expenses_price_1 = easy_money.sum_all_expected_expenses(:price1, options)
    self.sum_of_all_expected_revenues_price_1 = easy_money.sum_all_expected_revenues(:price1, options)
    self.sum_of_all_other_revenues_price_1    = easy_money.sum_all_other_revenues(:price1, options)
    self.sum_of_all_expected_expenses_price_2 = easy_money.sum_all_expected_expenses(:price2, options)
    self.sum_of_all_expected_revenues_price_2 = easy_money.sum_all_expected_revenues(:price2, options)
    self.sum_of_all_other_revenues_price_2    = easy_money.sum_all_other_revenues(:price2, options)

    if rate_type_internal
      self.sum_of_time_entries_expenses_internal      = easy_money.sum_time_entry_expenses(rate_type_internal.id, options)

      self.sum_of_all_other_expenses_price_1_internal = easy_money.sum_all_other_and_travel_expenses(:price1, rate_type_internal.id, options)
      self.sum_of_all_other_expenses_price_2_internal = easy_money.sum_all_other_and_travel_expenses(:price2, rate_type_internal.id, options)

      self.other_profit_price_1_internal              = easy_money.other_profit(:price1, rate_type_internal.id, options)
      self.other_profit_price_2_internal              = easy_money.other_profit(:price2, rate_type_internal.id, options)
    end

    if rate_type_external
      self.sum_of_time_entries_expenses_external      = easy_money.sum_time_entry_expenses(rate_type_external.id, options)

      self.sum_of_all_other_expenses_price_1_external = easy_money.sum_all_other_and_travel_expenses(:price1, rate_type_external.id, options)
      self.sum_of_all_other_expenses_price_2_external = easy_money.sum_all_other_and_travel_expenses(:price2, rate_type_external.id, options)

      self.other_profit_price_1_external              = easy_money.other_profit(:price1, rate_type_external.id, options)
      self.other_profit_price_2_external              = easy_money.other_profit(:price2, rate_type_external.id, options)
    end

    self.sum_of_all_travel_costs_price_1    = easy_money.sum_all_travel_costs(:price1, options)
    self.sum_of_all_travel_expenses_price_1 = easy_money.sum_all_travel_expenses(:price1, options)

    self.expected_profit_price_1            = easy_money.expected_profit(:price1, options)
    self.expected_profit_price_2            = easy_money.expected_profit(:price2, options)


    self.average_hourly_rate_price_1        = easy_money.average_hourly_rate(:price1, options)
    self.average_hourly_rate_price_2        = easy_money.average_hourly_rate(:price2, options)

    self.profit_margin                      = easy_money.gross_margin
    self.cost_ratio                         = easy_money.cost_ratio
  end

end
