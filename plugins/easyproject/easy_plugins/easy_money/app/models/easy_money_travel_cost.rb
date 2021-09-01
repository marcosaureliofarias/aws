class EasyMoneyTravelCost < ActiveRecord::Base
  include EasyMoney::EasyMoneyBaseModel

  # breaks further column decorations (e.g. serialize) if called in an included module
  acts_as_taggable_on :tags, :plugin_name => :easy_money
  acts_as_easy_currency :price1, :easy_currency_code, :spent_on

  remove_validation :vat, 'validates_numericality_of'
  remove_validation :price2, 'validates_numericality_of'
  validates_numericality_of :metric_units, :allow_nil => true
  validates_numericality_of :price_per_unit, :allow_nil => true

  after_create_commit :send_notification_added
  after_update_commit :send_notification_updated

  delete_safe_attribute 'price2'
  delete_safe_attribute 'vat'
  safe_attributes 'metric_units', 'price_per_unit'

  def self.name_without_prefix
    'travel_cost'
  end

  def self.css_icon
    'icon icon-money easy-money'
  end

  def price_per_unit
    price = read_attribute(:price_per_unit)
    if price.zero?
      travel_cost_price_per_unit.try(:unit_rate, easy_currency_code) || 0.0
    else
      price
    end
  end

  def travel_cost_price_per_unit
    @travel_cost_price_per_unit ||= EasyMoneyRate.find_rate_for_setting(:travel_cost_price_per_unit, project_from_entity.try(:id))
  end

  def easy_currency_code
    read_attribute(:easy_currency_code) || travel_cost_price_per_unit.try(:easy_currency_code) || project_from_entity.try(:easy_currency_code) || EasyCurrency.default_code
  end

  protected

  def send_notification_added
    if Setting.notified_events.include?('easy_money_travel_cost_added')
      EasyMoneyMailer.easy_money_travel_cost_added(self).deliver
    end
  end

  def send_notification_updated
    if Setting.notified_events.include?('easy_money_travel_cost_updated')
      EasyMoneyMailer.easy_money_travel_cost_updated(self).deliver
    end
  end

end
