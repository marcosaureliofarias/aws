class ChangeKeywordDefaultValue < ActiveRecord::Migration[4.2]
  def self.up
    change_column :easy_helpdesk_project_slas, :keyword, :string, {:null => false, :limit => 255, :default => ''}
  end

  def self.down
    change_column :easy_helpdesk_project_slas, :keyword, :string, {:null => false, :limit => 255}
  end
end
