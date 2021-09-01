class AddIndexUpdatedOnToIssues < ActiveRecord::Migration[4.2]
  def self.up
    add_index :issues, :updated_on, name: 'index_issues_on_updated_on'
  end

  def self.down
    remove_index :issues, name: 'index_issues_on_updated_on'
  end
end
