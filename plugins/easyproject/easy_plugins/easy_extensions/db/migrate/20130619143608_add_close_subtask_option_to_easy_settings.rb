class AddCloseSubtaskOptionToEasySettings < ActiveRecord::Migration[4.2]
  def change
    EasySetting.create(:name => 'close_subtask_after_parent', :value => false)
  end
end
