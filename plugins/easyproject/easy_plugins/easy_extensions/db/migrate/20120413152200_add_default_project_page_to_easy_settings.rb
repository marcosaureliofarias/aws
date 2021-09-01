class AddDefaultProjectPageToEasySettings < ActiveRecord::Migration[4.2]
  def self.up
    EasySetting.create(:name => 'default_project_page', :value => 'project_overview')
  end

  def self.down
    EasySetting.where(:name => 'default_project_page').destroy_all
  end
end
