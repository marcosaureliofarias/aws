class AlertContext < ActiveRecord::Base
  self.table_name = 'easy_alert_contexts'

  default_scope{order("#{AlertContext.table_name}.position ASC")}

  has_many :rules, :class_name => 'AlertRule', :foreign_key => 'context_id'

  scope :named, lambda {|keyword| where(self.arel_table[:name].lower.eq(keyword.to_s.strip.downcase)) }

  acts_as_positioned

  validates :name, :presence => true

  def sort_rules
    self.rules.sort_by(&:translated_name)
  end

  def translated_name
    l("easy_alerts_context.#{self.name}".to_sym).html_safe
  end

  def visible?(user = nil)
    u = user || User.current
    return false if self.name == 'helpdesk'
    return false if self.name == 'invoice' && !Redmine::Plugin.installed?(:easy_invoicing)

    return true
  end

end
