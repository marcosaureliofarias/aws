class AddEasyHelpdeskProjectQuerySettings < ActiveRecord::Migration[4.2]

  def self.up
    EasySetting.create(:name => 'easy_helpdesk_project_query_list_default_columns', :value => ['project', 'tracker', 'assigned_to', 'matching_emails', 'monthly_hours'])
  end

  def self.down
    EasySetting.where(:name => 'easy_helpdesk_project_query_list_default_columns').destroy_all
  end
end