class AddMilestoneQueries < ActiveRecord::Migration[4.2]

  def self.up
    AlertRule.create!(:name => 'easy_version_query', :context_id => AlertContext.named('milestone').first.id, :class_name => 'EasyAlerts::Rules::EasyVersionQuery')
  end

  def self.down
  end

end