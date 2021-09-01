class AddMoveVersionEffectiveDateAfterChangeIssueDueDateOptionToEasySetting < ActiveRecord::Migration[4.2]
  def self.up
    EasySetting.create(:name => 'milestone_effective_date_from_issue_due_date', :value => false)
  end

  def self.down
    EasySetting.where(:name => 'milestone_effective_date_from_issue_due_date').destroy_all
  end
end
