class EasyMoneySettings < ActiveRecord::Base
  self.table_name = 'easy_money_settings'

  SETTINGS_WITH_PRICE_RATE = %w[expected_payroll_expense_rate travel_cost_price_per_unit travel_expense_price_per_day]

  belongs_to :project

  validates_length_of :name, :in => 1..255, :allow_nil => false
  validates_length_of :value, :in => 0..255, :allow_nil => true

  after_save :invalidate_cache
  after_save :update_easy_money_rate, if: :easy_money_rate_required?
  after_destroy :invalidate_cache

  after_update :destroy_project_revenues, if: :destroy_project_revenues_required?
  after_update :destroy_project_expenses, if: :destroy_project_expenses_required?


  attr_accessor :easy_currency_code

  def self.project_settings_names
    ['currency', 'price_visibility', 'rate_type', 'include_childs', 'expected_visibility', 'expected_count_price',
      'expected_rate_type', 'vat', 'revenues_type', 'expenses_type', 'expected_payroll_expense_type', 'expected_payroll_expense_rate',
      'use_easy_money_for_versions', 'use_easy_money_for_issues', 'use_easy_money_for_easy_crm_cases', 'round_on_list',
      'use_travel_expenses', 'use_travel_costs', 'travel_cost_price_per_unit', 'travel_expense_price_per_day', 'travel_metric_unit']
  end

  def self.global_settings_names
    ['currency_visible']
  end

  def self.find_settings_by_name(key, project_or_project_id = nil)
    if project_or_project_id.is_a?(Project)
      project_id = project_or_project_id.id
    elsif !project_or_project_id.nil?
      project_id = project_or_project_id.to_i
    else
      project_id = nil
    end

    cache_key =  "EasyMoneySetting/#{key}/#{project_id}"
    fallback_cache_key = "EasyMoneySetting/#{key}/"

    cached_value = Rails.cache.fetch cache_key do
      EasyMoneySettings.where(name: key, project_id: project_id).pluck(:value).first
    end

    if cached_value.nil? || cached_value == ''
      Rails.cache.fetch fallback_cache_key do
        EasyMoneySettings.where(name: key, project_id: nil).pluck(:value).first
      end
    else
      return cached_value
    end
  end

  def invalidate_cache
    Rails.cache.delete "EasyMoneySetting/#{self.name}/#{self.project_id}"
  end

  def self.copy_to(project_from, project_to)
    EasyMoneySettings.where(:project_id => project_from.id).all.each do |project_from_setting|
      setting = project_from_setting.dup
      setting.project_id = project_to.id
      setting.save
    end
  end

  def self.currency_visible?
    EasyMoney::SettingsResolver.new(self.global_settings_names).currency_visible?
  end

  def easy_money_rate_required?
    name.in? EasyMoneySettings::SETTINGS_WITH_PRICE_RATE
  end

  def update_easy_money_rate
    easy_money_rate_scope = EasyMoneyRate.where(rate_type_id: EasyMoneyRateType.default&.id, entity: self, project_id: project_id)

    EasyMoneyRate.transaction do
      easy_money_rate_scope.delete_all
      if value.present? && value.to_f >= 0.0
        easy_money_rate = easy_money_rate_scope.build
        easy_money_rate.unit_rate = value
        easy_money_rate.easy_currency_code = easy_currency_code || project&.easy_currency_code || EasyCurrency.default_code
        easy_money_rate.save!
      end
    end
  end

  def destroy_project_revenues_required?
    project_id? && name == 'revenues_type' && saved_change_to_value?
  end

  def destroy_project_revenues
    project.expected_revenues.destroy_all
    project.other_revenues.destroy_all
  end

  def destroy_project_expenses_required?
    project_id? && name == 'expenses_type' && saved_change_to_value?
  end

  def destroy_project_expenses
    project.expected_expenses.destroy_all
    project.other_expenses.destroy_all
  end

end
