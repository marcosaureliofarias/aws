class AddDefaultForMailbox < ActiveRecord::Migration[4.2]

  def self.up
    add_column :easy_helpdesk_projects, :default_for_mailbox_id, :integer, {:null => true}
  end

  def self.down
    remove_column :easy_helpdesk_projects, :default_for_mailbox_id
  end
end