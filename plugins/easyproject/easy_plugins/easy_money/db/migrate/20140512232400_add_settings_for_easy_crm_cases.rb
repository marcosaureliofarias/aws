class AddSettingsForEasyCrmCases < ActiveRecord::Migration[4.2]
  def self.up

    EasyMoneySettings.create :name => 'use_easy_money_for_easy_crm_cases', :project_id => nil, :value => '0'

  end

  def self.down
  end
end