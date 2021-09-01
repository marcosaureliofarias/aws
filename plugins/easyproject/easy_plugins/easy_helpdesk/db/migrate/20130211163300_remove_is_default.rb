class RemoveIsDefault < ActiveRecord::Migration[4.2]

  def self.up
    remove_column :easy_helpdesk_projects, :is_default
  end

  def self.down
  end
end