class EasyMoneyPeriodicalEntityItem < ActiveRecord::Base
  include Redmine::SafeAttributes
  extend EasyMoney::EasyCurrencyRecalculateMixin

  belongs_to :easy_money_periodical_entity
  belongs_to :author, :class_name => 'User', :foreign_key => 'author_id'
  belongs_to :easy_currency, foreign_key: :easy_currency_code, primary_key: :iso_code

  scope :sorted_by_period, lambda { order("#{EasyMoneyPeriodicalEntityItem.table_name}.period_date DESC") }
  scope :for_period, lambda {|period_date| where(["#{EasyMoneyPeriodicalEntityItem.table_name}.period_date = ?", period_date]) }
  scope :until_period, lambda {|*period_date| sorted_by_period.where(["#{EasyMoneyPeriodicalEntityItem.table_name}.period_date <= ?", period_date.first || Date.today]) }
  scope :above_period, lambda {|*period_date| sorted_by_period.where(["#{EasyMoneyPeriodicalEntityItem.table_name}.period_date >= ?", period_date.first || Date.today]) }

  validates :easy_money_periodical_entity_id, :author_id, :period_date, :presence => true

  html_fragment :description, :scrub => :strip

  acts_as_customizable
  acts_as_easy_currency :price1, :easy_currency_code, :period_date
  acts_as_easy_currency :price2, :easy_currency_code, :period_date

  safe_attributes 'author_id', 'period_date', 'name', 'description', 'price1', 'price2', 'vat', 'custom_field_values', 'custom_fields',
    :if => lambda {|empei, user| empei.new_record? || empei.editable?(user)}

  def editable?(user = nil)
    return true
  end

  def visible?(user = nil)
    return true
  end

  # Overrides Redmine::Acts::Customizable::InstanceMethods#available_custom_fields
  def available_custom_fields
    easy_money_periodical_entity ? easy_money_periodical_entity.available_custom_fields : []
  end

end
