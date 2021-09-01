class CorrectProjectsActivities < ActiveRecord::Migration[4.2]
  def self.up
    s = EasySetting.where(:name => 'enable_activity_roles').first
    unless s
      EasySetting.create(:name => 'enable_activity_roles', :value => (!Project.all.detect { |p| (p.activities.count * p.all_members_roles.count) != p.project_activity_roles.length }.nil?))
    end
  end

  def self.down
    EasySetting.where(:name => 'enable_activity_roles').destroy_all
  end
end
