class AddEasyHelpdeskTicketOwnerToIssue < ActiveRecord::Migration[5.2]
  def up
    add_column :issues, :easy_helpdesk_ticket_owner_id, :integer, index: true
  end

  def down
    remove_column :issues, :easy_helpdesk_ticket_owner_id
  end
end
