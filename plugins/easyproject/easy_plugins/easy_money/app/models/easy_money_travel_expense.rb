class EasyMoneyTravelExpense < ActiveRecord::Base
  include EasyMoney::EasyMoneyBaseModel

  # breaks further column decorations (e.g. serialize) if called in an included module
  acts_as_taggable_on :tags, :plugin_name => :easy_money
  acts_as_easy_currency :price1, :easy_currency_code, :spent_on

  remove_validation :vat, 'validates_numericality_of'
  remove_validation :price2, 'validates_numericality_of'
  validate :date_validation
  belongs_to :user, :class_name => 'Principal', :foreign_key => 'user_id'

  after_create_commit :send_notification_added
  after_update_commit :send_notification_updated

  delete_safe_attribute 'price2'
  delete_safe_attribute 'vat'
  safe_attributes 'user_id', 'price_per_day', 'spent_on_to'

  def self.name_without_prefix
    'travel_expense'
  end

  def self.css_icon
    'icon icon-money easy-money'
  end

  def spent_on_to=(value)
    date = value.respond_to?(:call) ? value.call : value
    super date
  end

  def price_per_day
    price = read_attribute(:price_per_day)
    if price.zero?
      travel_expense_price_per_day.try(:unit_rate, easy_currency_code) || 0.0
    else
      price
    end
  end

  def travel_expense_price_per_day
    @travel_cost_price_per_unit ||= EasyMoneyRate.find_rate_for_setting(:travel_expense_price_per_day, project_from_entity.try(:id))
  end

  def easy_currency_code
    read_attribute(:easy_currency_code) || travel_expense_price_per_day.try(:easy_currency_code) || project_from_entity.try(:easy_currency_code) || EasyCurrency.default_code
  end

  def days_count
    spent_on_to? && spent_on? ? (spent_on_to - spent_on + 1) : 0
  end

  protected

  def send_notification_added
    if Setting.notified_events.include?('easy_money_travel_expense_added')
      EasyMoneyMailer.easy_money_travel_expense_added(self).deliver
    end
  end

  def send_notification_updated
    if Setting.notified_events.include?('easy_money_travel_expense_updated')
      EasyMoneyMailer.easy_money_travel_expense_updated(self).deliver
    end
  end

  def date_validation
    if self.spent_on && self.spent_on_to && ((self.spent_on_to - self.spent_on).to_i < 0)
      errors.add :base, l(:easy_money_date_greater_or_equal, :start_date => "#{self.spent_on.day}. #{self.spent_on.month}.", :due_date => "#{self.spent_on_to.day}. #{self.spent_on_to.month}.")
    end
  end

end
