# encoding: utf-8
module EasyHelpdesk

  def self.ensure_all_features
    ensure_easy_alert_sla_due_time
    ensure_easy_alert_sla_spent_time
    ensure_easy_alert_sla_responding_time
  end

  def self.alert_helpdesk_monitor_due_time_manager_alert
    @alert_helpdesk_monitor_due_time_manager_alert ||= Alert.where(:builtin => (Alert.builtin_for_plugin(:EasyHelpdesk) + 1)).first
  end

  def self.alert_helpdesk_monitor_due_time_manager_warning
    @alert_helpdesk_monitor_due_time_manager_warning ||= Alert.where(:builtin => (Alert.builtin_for_plugin(:EasyHelpdesk) + 2)).first
  end

  def self.alert_helpdesk_monitor_due_time_assignee_alert
    @alert_helpdesk_monitor_due_time_assignee_alert ||= Alert.where(:builtin => (Alert.builtin_for_plugin(:EasyHelpdesk) + 3)).first
  end

  def self.alert_helpdesk_monitor_due_time_assignee_warning
    @alert_helpdesk_monitor_due_time_assignee_warning ||= Alert.where(:builtin => (Alert.builtin_for_plugin(:EasyHelpdesk) + 4)).first
  end

  def self.alert_helpdesk_monitor_prepaid_hours_alert
    @alert_helpdesk_monitor_prepaid_hours_alert ||= Alert.where(:builtin => (Alert.builtin_for_plugin(:EasyHelpdesk) + 5)).first
  end

  def self.alert_helpdesk_monitor_prepaid_hours_warning
    @alert_helpdesk_monitor_prepaid_hours_warning ||= Alert.where(:builtin => (Alert.builtin_for_plugin(:EasyHelpdesk) + 6)).first
  end

  def self.alert_helpdesk_monitor_hours_to_response_alert
    @alert_helpdesk_monitor_hours_to_response_alert ||= Alert.where(:builtin => (Alert.builtin_for_plugin(:EasyHelpdesk) + 7)).first
  end

  def self.ensure_easy_alert_sla_due_time
    return unless Object.const_defined?(:EasyAlerts) && ActiveRecord::Base.connection.table_exists?(AlertRule.table_name)

    rule = AlertRule.named('helpdesk_monitor_due_time_manager').first
    return unless rule

    builtin_alert_manager = Alert.builtin_for_plugin(:EasyHelpdesk) + 1
    unless EasyHelpdesk.alert_helpdesk_monitor_due_time_manager_alert
      alert_type = AlertType.named('alert').first || AlertType.default || AlertType.first

      a = Alert.new(:author => User.anonymous, :rule => rule,
        :name => 'Helpdesk - monitor support tickets due time (manager)', :is_for => 'only_me', :mail_for => 'custom', :builtin => builtin_alert_manager)
      a.type = alert_type
      a.rule_settings = {:percentage => 100}
      a.save!(:validate => false)
    end

    builtin_warning_manager = Alert.builtin_for_plugin(:EasyHelpdesk) + 2
    unless EasyHelpdesk.alert_helpdesk_monitor_due_time_manager_warning
      alert_type = AlertType.named('warning').first || AlertType.default || AlertType.first

      a = Alert.new(:author => User.anonymous, :rule => rule,
        :name => 'Helpdesk - monitor support tickets due time (manager)', :is_for => 'only_me', :mail_for => 'custom', :builtin => builtin_warning_manager)
      a.type = alert_type
      a.rule_settings = {:percentage => 75}
      a.save!(:validate => false)
    end

    rule = AlertRule.named('helpdesk_monitor_due_time_assignee').first
    return unless rule

    builtin_alert_assignee = Alert.builtin_for_plugin(:EasyHelpdesk) + 3
    unless EasyHelpdesk.alert_helpdesk_monitor_due_time_assignee_alert
      alert_type = AlertType.named('alert').first || AlertType.default || AlertType.first

      a = Alert.new(:author => User.anonymous, :rule => rule,
        :name => 'Helpdesk - monitor support tickets due time (assignee)', :is_for => 'all', :mail_for => 'all', :builtin => builtin_alert_assignee)
      a.type = alert_type
      a.rule_settings = {:percentage => 100}
      a.save!(:validate => false)
    end

    builtin_warning_assignee = Alert.builtin_for_plugin(:EasyHelpdesk) + 4
    unless EasyHelpdesk.alert_helpdesk_monitor_due_time_assignee_warning
      alert_type = AlertType.named('warning').first || AlertType.default || AlertType.first

      a = Alert.new(:author => User.anonymous, :rule => rule,
        :name => 'Helpdesk - monitor support tickets due time (assignee)', :is_for => 'all', :mail_for => 'all', :builtin => builtin_warning_assignee)
      a.type = alert_type
      a.rule_settings = {:percentage => 75}
      a.save!(:validate => false)
    end
  end

  def self.ensure_easy_alert_sla_spent_time
    return unless Object.const_defined?(:EasyAlerts) && ActiveRecord::Base.connection.table_exists?(AlertRule.table_name)

    rule = AlertRule.named('helpdesk_monitor_prepaid_hours').first
    return unless rule

    builtin_alert = Alert.builtin_for_plugin(:EasyHelpdesk) + 5
    unless EasyHelpdesk.alert_helpdesk_monitor_prepaid_hours_alert
      alert_type = AlertType.named('alert').first || AlertType.default || AlertType.first

      a = Alert.new(:author => User.anonymous, :rule => rule,
        :name => 'Helpdesk - monitor support tickets prepaid hours', :is_for => 'only_me', :mail_for => 'custom', :builtin => builtin_alert)
      a.type = alert_type
      a.rule_settings = {:percentage => 100}
      a.save!(:validate => false)
    end

    builtin_warning = Alert.builtin_for_plugin(:EasyHelpdesk) + 6
    unless EasyHelpdesk.alert_helpdesk_monitor_prepaid_hours_warning
      alert_type = AlertType.named('warning').first || AlertType.default || AlertType.first

      a = Alert.new(:author => User.anonymous, :rule => rule,
        :name => 'Helpdesk - monitor support tickets prepaid hours', :is_for => 'only_me', :mail_for => 'custom', :builtin => builtin_warning)
      a.type = alert_type
      a.rule_settings = {:percentage => 75}
      a.save!(:validate => false)
    end
  end

  def self.ensure_easy_alert_sla_responding_time
    return unless Object.const_defined?(:EasyAlerts) && ActiveRecord::Base.connection.table_exists?(AlertRule.table_name)

    rule = AlertRule.named('helpdesk_monitor_hours_to_response').first
    return unless rule

    builtin_alert = Alert.builtin_for_plugin(:EasyHelpdesk) + 7
    unless EasyHelpdesk.alert_helpdesk_monitor_hours_to_response_alert
      alert_type = AlertType.named('alert').first || AlertType.default || AlertType.first

      a = Alert.new(:author => User.anonymous, :rule => rule,
        :name => 'Helpdesk - monitor support tickets hours to response', :is_for => 'only_me', :mail_for => 'custom', :builtin => builtin_alert)
      a.type = alert_type
      a.rule_settings = {:percentage => 90}
      a.save!(:validate => false)
    end
  end

  def self.override_attributes
    #['project', 'tracker', 'status', 'priority', 'category', 'assigned_to', 'fixed_version', 'start_date', 'due_date', 'estimated_hours', 'done_ratio']
    ['all']
  end

  def self.easy_setting_booleans
    [:easy_helpdesk_allow_override, :easy_helpdesk_ignore_cc, :easy_helpdesk_allow_custom_sender]
  end

  # First is default for migration
  def self.sender_setting
    @sender_setting ||= ['current_user', 'redmine_default', 'mailbox_address']
  end

end
