class AddCrmStatuses1 < ActiveRecord::Migration[4.2]
  def self.up
    EasyCrmCaseStatus.create(:name => 'Sale', :internal_name => 'sale', :is_default => false)
  end

  def self.down
  end

end
