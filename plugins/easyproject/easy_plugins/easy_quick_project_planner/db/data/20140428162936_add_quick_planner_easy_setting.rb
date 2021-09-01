class AddQuickPlannerEasySetting < ActiveRecord::Migration[4.2]
  def up
    EasySetting.create(:name => 'quick_planner_fields', :value => ['subject', 'estimated_hours', 'due_date'])
  end

  def down
    EasySetting.where(:name => 'quick_planner_fields').destroy_all
  end
end
