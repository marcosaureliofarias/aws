class AddBillingInfoIntoEasySettings < ActiveRecord::Migration[4.2]
  def self.up
    EasySetting.create(:name => 'show_billable_things', :value => false)
  end

  def self.down
    EasySetting.where(:name => 'show_billable_things').destroy_all
  end
end
