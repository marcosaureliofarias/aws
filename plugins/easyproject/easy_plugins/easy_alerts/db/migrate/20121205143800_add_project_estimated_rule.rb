class AddProjectEstimatedRule < ActiveRecord::Migration[4.2]

  def self.up
    AlertRule.create :name => 'project_estimated_hours', :context_id => AlertContext.named('project').first.id, :class_name => 'EasyAlerts::Rules::ProjectEstimatedHours', :position => 9
  end

  def self.down
  end
  
end