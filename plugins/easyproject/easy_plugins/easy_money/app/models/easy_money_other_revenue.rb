class EasyMoneyOtherRevenue < ActiveRecord::Base
  include EasyMoney::EasyMoneyBaseModel

  acts_as_easy_repeatable

  # breaks further column decorations (e.g. serialize) if called in an included module
  acts_as_taggable_on :tags, :plugin_name => :easy_money
  acts_as_easy_currency :price1, :easy_currency_code, :spent_on
  acts_as_easy_currency :price2, :easy_currency_code, :spent_on

  belongs_to :repeating_revenue, :class_name => 'EasyMoneyOtherRepeatingRevenue', :foreign_key => 'repeating_id'

  has_many :easy_entity_assigned, :class_name => 'EasyEntityAssignment', :as => :entity_to, :dependent => :delete_all

  after_create_commit :send_notification_added
  after_update_commit :send_notification_updated

  def self.name_without_prefix
    'other_revenue'
  end

  def self.css_icon
    'icon icon-money easy-money'
  end

  protected

  def send_notification_added
    if Setting.notified_events.include?('easy_money_other_revenue_added')
      EasyMoneyMailer.easy_money_other_revenue_added(self).deliver
    end
  end

  def send_notification_updated
    if Setting.notified_events.include?('easy_money_other_revenue_updated')
      EasyMoneyMailer.easy_money_other_revenue_updated(self).deliver
    end
  end

end
