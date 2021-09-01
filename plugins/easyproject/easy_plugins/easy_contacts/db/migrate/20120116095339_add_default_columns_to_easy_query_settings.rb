class AddDefaultColumnsToEasyQuerySettings < ActiveRecord::Migration[4.2]
  def self.up
    EasySetting.create(:name => 'easy_contact_query_list_default_columns', :value => ['contact_name'])
    EasySetting.create(:name => 'easy_contact_group_query_list_default_columns', :value => ['group_name'])
  end

  def self.down
    EasySetting.where({:name => 'easy_contact_query_list_default_columns'}).destroy_all
    EasySetting.where({:name => 'easy_contact_group_query_list_default_columns'}).destroy_all
  end
end
