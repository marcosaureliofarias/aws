class ChangeDefaultPositionToNull < ActiveRecord::Migration[4.2]
  def up
    [
        :easy_attendance_activities,
        :easy_page_available_zones,
        :easy_page_template_modules,
        :easy_page_template_tabs,
        :easy_page_templates,
        :easy_page_user_tabs,
        :easy_page_zone_modules,
        :easy_user_time_calendars,
        :easy_user_types
    ].each do |t|
      change_column t, :position, :integer, { :null => true, :default => nil }
    end
  end

  def down
  end
end
