class DeleteEasySettingsTimeEntry < ActiveRecord::Migration[4.2]
  def self.up
    names = [:spent_on_limit_before_today, :spent_on_limit_before_today_edit, :spent_on_limit_after_today, :spent_on_limit_after_today_edit,
             :timelog_comment_editor_enabled, :time_entry_spent_on_at_issue_update_enabled, :time_entry_spent_on_at_issue_update_enabled,
             :allow_log_time_to_closed_issue, :required_issue_id_at_time_entry, :show_time_entry_range_select]

    egtes = EasyGlobalTimeEntrySetting.new(names.inject({}) do |g, setting|
      value      = EasySetting.value(setting)
      g[setting] = value
      g
    end
    )
    EasySetting.where(:name => names).destroy_all if egtes.save
  end

  def self.down
  end
end