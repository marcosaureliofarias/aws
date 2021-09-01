class AddEasyReopenAtToIssue < ActiveRecord::Migration[4.2]
  def self.up
    add_column :issues, :easy_reopen_at, :datetime, {:null => true}
    Issue.reset_column_information
  end

  def self.down
    remove_column :issues, :easy_reopen_at
  end
end
