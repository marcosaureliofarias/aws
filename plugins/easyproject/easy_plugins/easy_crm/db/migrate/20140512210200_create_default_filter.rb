class CreateDefaultFilter < ActiveRecord::Migration[4.2]
  def self.up
    EasySetting.create(:name => 'easy_crm_case_query_default_filters', :value => {'is_canceled' => {:operator=>'=', :values => ['0']}})
  end

  def self.down
    EasySetting.where(:name => 'easy_crm_case_query_default_filters').destroy_all
  end

end
