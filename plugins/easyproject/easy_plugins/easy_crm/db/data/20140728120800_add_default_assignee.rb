class AddDefaultAssignee < ActiveRecord::Migration[4.2]

  def self.up

    EasySetting.create :name => 'crm_default_assignee', :value => ''

  end

  def self.down

    EasySetting.where(:name => 'crm_default_assignee').destroy_all

  end

end
