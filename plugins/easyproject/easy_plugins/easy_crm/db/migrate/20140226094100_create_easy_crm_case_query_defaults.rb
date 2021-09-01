class CreateEasyCrmCaseQueryDefaults < ActiveRecord::Migration[4.2]
  def self.up
    EasySetting.create(:name => 'easy_crm_case_query_list_default_columns', :value => ['name', 'assigned_to', 'due_date', 'price', 'email', 'telephone'])
    EasySetting.create(:name => 'easy_crm_case_query_grouped_by', :value => 'easy_crm_case_status')

    if sett = EasySetting.where(:name => 'easy_contact_query_list_default_columns').first
      EasySetting.create(:name => 'easy_crm_contact_query_list_default_columns', :value => sett.value)
    else
      EasySetting.create(:name => 'easy_crm_contact_query_list_default_columns', :value => ['contact_name'])
    end
  end

  def self.down
    EasySetting.where(:name => 'easy_crm_case_query_list_default_columns').destroy_all
    EasySetting.where(:name => 'easy_crm_case_query_grouped_by').destroy_all
    EasySetting.where(:name => 'easy_crm_contact_query_list_default_columns').destroy_all
  end

end
