class AddKeywordToEasyHelpdeskProject < ActiveRecord::Migration[4.2]
  def self.up
    add_column :easy_helpdesk_projects, :keyword, :string, {:null => false, :limit => 255, :default => ''}
    EasyHelpdeskProject.reset_column_information
  end

  def self.down
    remove_column :easy_helpdesk_projects, :keyword
    EasyHelpdeskProject.reset_column_information
  end
end