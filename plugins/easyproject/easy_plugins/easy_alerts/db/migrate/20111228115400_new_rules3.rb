class NewRules3 < ActiveRecord::Migration[4.2]

  def self.up
    AlertRule.create :name => "easy_project_query", :context_id => AlertContext.named('project').first.id, :class_name => "EasyAlerts::Rules::EasyProjectQuery"
  end

  def self.down
  end
end