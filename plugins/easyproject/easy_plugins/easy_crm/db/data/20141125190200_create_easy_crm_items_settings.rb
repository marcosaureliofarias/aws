class CreateEasyCrmItemsSettings < ActiveRecord::Migration[4.2]
  def self.up
    EasySetting.create(:name => 'easy_crm_use_items', :value => false)
  end

  def self.down
    EasySetting.where(:name => 'easy_crm_use_items').destroy_all
  end

end
