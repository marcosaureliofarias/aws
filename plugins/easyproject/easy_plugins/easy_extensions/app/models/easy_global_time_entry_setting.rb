class EasyGlobalTimeEntrySetting < ActiveRecord::Base
  include Redmine::SafeAttributes

  safe_attributes 'role_id',
                  'spent_on_limit_before_today',
                  'spent_on_limit_before_today_edit',
                  'spent_on_limit_after_today',
                  'spent_on_limit_after_today_edit',
                  'timelog_comment_editor_enabled',
                  'time_entry_spent_on_at_issue_update_enabled',
                  'allow_log_time_to_closed_issue',
                  'required_issue_id_at_time_entry',
                  'show_time_entry_range_select',
                  'time_entry_daily_limit',
                  'required_time_entry_comments'

  belongs_to :role

  def self.value(setting, roles)
    roles = Array.wrap(roles)
    if roles.any?
      role     = roles.min_by(&:position)
      settings = self.find_by(role_id: role.id)
      value    = settings.send(setting.to_sym) if settings
      return value unless value.nil?
    end

    # default value
    default_value = self.find_by(:role_id => nil)
    if default_value
      return default_value.send(setting.to_sym)
    else
      return nil
    end
  end

end
