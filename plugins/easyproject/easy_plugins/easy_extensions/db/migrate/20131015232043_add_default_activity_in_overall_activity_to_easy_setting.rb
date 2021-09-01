class AddDefaultActivityInOverallActivityToEasySetting < ActiveRecord::Migration[4.2]
  def self.up
    EasySetting.create :name => 'default_activity_in_overall_activity', :value => Redmine::Activity.default_event_types
  end

  def self.down
    EasySetting.where(:name => 'default_activity_in_overall_activity').destroy_all
  end
end
