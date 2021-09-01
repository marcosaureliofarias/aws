class AddMailSource < ActiveRecord::Migration[4.2]

  def self.up
    add_column :easy_helpdesk_project_matchings, :email_field, :string, {:null => false, :default => 'from'}
  end

  def self.down
    remove_column :easy_helpdesk_project_matchings, :email_field
  end
end