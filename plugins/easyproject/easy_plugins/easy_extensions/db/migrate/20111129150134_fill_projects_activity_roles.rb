class FillProjectsActivityRoles < ActiveRecord::Migration[4.2]
  def self.up
    Project.all.find_each(:batch_size => 50) do |project|
      activities = project.activities(false, true)
      unless activities.blank?
        activities.each do |activity|
          member_roles = project.all_members_roles
          unless member_roles.blank?
            member_roles.each do |role|
              project.project_activity_roles << ProjectActivityRole.new(:activity_id => activity.id, :role_id => role.id)
            end
          end
        end
      end
    end
  end

  def self.down
    Project.connection.execute('TRUNCATE projects_activity_roles')
  end
end
