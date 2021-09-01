class AddEasyHelpdeskMailboxUsername < ActiveRecord::Migration[4.2]

  def self.up
    add_column :issues, :easy_helpdesk_mailbox_username, :string, {:null => true, :limit => 2048}
  end

  def self.down
    remove_column :issues, :easy_helpdesk_mailbox_username
  end
end