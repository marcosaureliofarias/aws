class AlertRule < ActiveRecord::Base
  self.table_name = 'easy_alert_rules'

  default_scope{order("#{AlertRule.table_name}.position ASC")}

  belongs_to :context, :class_name => 'AlertContext', :foreign_key => 'context_id'

  has_many :alerts, :class_name => 'Alert', :foreign_key => 'rule_id', :dependent => :destroy

  scope :named, lambda {|keyword| where(self.arel_table[:name].lower.eq(keyword.to_s.strip.downcase)) }

  acts_as_positioned

  validates :name, :presence => true
  validates :class_name, :presence => true

  def translated_name
    l("easy_alerts_rule.#{self.name}".to_sym).html_safe
  end

  def get_settings_form
    "alert_rules/#{self.name}_form"
  end

  def get_render_view
    "alert_rules/#{self.name}_report"
  end

  def get_render_view_email_html
    "alert_rules/#{self.name}_email.html"
  end

  def get_render_view_email_plain
    "alert_rules/#{self.name}_email.text"
  end

  def validate_alert(alert)
    rule_class.validate_alert(alert)
  end

  def serialize_settings(params)
    rule_class.serialize_settings_to_hash(params)
  end

  def initialize_settings(params)
    rule_class.initialize_from_params(params)
  end

  def generate_reports(alert, user = nil)
    user ||= User.current

    rule_class.initialize_from_alert(alert)
    results = rule_class.find_items(alert, user)

    return if results.nil?

    if (results.is_a?(Array)) && results.blank? && alert.rule_settings.has_key?(:operator)
      process_without_result(alert, user)
    elsif results.respond_to?(:each)
      existing_reports = get_existing_reports(alert, user)
      results.each do |result|
        process_result(alert, result, user, existing_reports)
      end
    else
      process_result(alert, results, user)
    end
  end

  def expires_at(alert)
    rule_class.expires_at(alert)
  end

  def mailer_template_name(alert)
    rule_class.mailer_template_name(alert)
  end

  def issue_provided?
    rule_class.issue_provided?
  end

  def self.active_rules
    return @active_rules unless @active_rules.nil?
    @active_rules = EasyAlerts::Rules::Base.descendants.reject {|rule| Redmine::Plugin.disabled?(rule.registered_in_plugin) }
  end

  private

  def rule_class
    return @rule_class unless @rule_class.nil?
    require "easy_alerts/rules/#{self.name}"
    @rule_class = self.class_name.constantize.new
  end

  def get_existing_reports(alert, user = nil)
    user ||= User.current
    exp = rule_class.expires_at(alert)
    scope = AlertReport.where(alert_id: alert.id, user_id: user.id)
    if exp.nil?
      scope = scope.where("#{AlertReport.table_name}.expires_at IS NULL")
    else
      scope = scope.where(["#{AlertReport.table_name}.expires_at >= ?", Time.now])
    end
    scope.having('COUNT(id) > 0').group('CONCAT(entity_type, entity_id)').select('CONCAT(entity_type, entity_id) AS e').map(&:e)
  end

  def process_result(alert, result, user = nil, existing_reports = nil)
    return if !result.respond_to?(:id)
    exp = rule_class.expires_at(alert)

    unless (existing_reports || get_existing_reports(alert, user)).include?("#{result.class}#{result.id}")
      AlertReport.create(alert_id: alert.id, entity_id: result.id, entity_type: result.class.to_s, user_id: user.id, archived: false, emailed: false, expires_at: exp)
    end
  end

  def process_without_result(alert, user = nil)
    user ||= User.current
    exp = rule_class.expires_at(alert)

    AlertReport.create(alert_id: alert.id, user_id: user.id, archived: false, emailed: false, expires_at: exp)
  end

end
