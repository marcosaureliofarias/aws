class AddEasyStatusUpdatedOnToIssues < ActiveRecord::Migration[4.2]
  def self.up
    add_column :issues, :easy_status_updated_on, :datetime, { :null => true }
  end

  def self.down
    remove_column :issues, :easy_status_updated_on
  end
end
