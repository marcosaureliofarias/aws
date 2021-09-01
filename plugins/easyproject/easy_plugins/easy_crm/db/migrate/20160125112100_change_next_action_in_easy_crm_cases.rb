class ChangeNextActionInEasyCrmCases < ActiveRecord::Migration[4.2]

  def up
    change_column :easy_crm_cases, :next_action, :datetime
  end

  def down
  end

end
