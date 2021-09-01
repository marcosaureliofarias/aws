class AddEasyUserAllocationByProjectToEasySettings < ActiveRecord::Migration[4.2]
  def up
    EasySetting.create(:name => 'easy_user_allocation_by_project_enabled', :value => false)
  end

  def down
    EasySetting.where(:name => 'easy_user_allocation_by_project_enabled').destroy_all
  end
end
