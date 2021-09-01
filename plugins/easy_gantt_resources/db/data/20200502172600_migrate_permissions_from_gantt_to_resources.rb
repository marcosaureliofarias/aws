class MigratePermissionsFromGanttToResources < EasyExtensions::EasyDataMigration
  def up
    begin
      Role.all.each do |role|
        begin
          role.add_permission! :view_easy_gantt_resources          if role.permissions.include? :view_easy_gantt
          role.add_permission! :edit_easy_gantt_resources          if role.permissions.include? :edit_easy_gantt
          role.add_permission! :view_global_easy_gantt_resources   if role.permissions.include? :view_global_easy_gantt
          role.add_permission! :edit_global_easy_gantt_resources   if role.permissions.include? :edit_global_easy_gantt
          role.add_permission! :view_personal_easy_gantt_resources if role.permissions.include? :view_personal_easy_gantt
          role.add_permission! :edit_personal_easy_gantt_resources if role.permissions.include? :edit_personal_easy_gantt
        rescue StandardError => e
          say "Failed to update Gantt / Resources permissions automatically for the role of #{role.id} / #{role.name}, please fix them manually if needed."
          say e.to_s + ': ' + e.message
        end
      end
    rescue StandardError => e
      say "Failed to update Gantt / Resources permissions automatically, please fix them manually if needed."
      say e.to_s + ': ' + e.message
    end
  end

  def down
  end
end
