class CreateHelpdeskMailTemplatesMailboxes < ActiveRecord::Migration[4.2]

  def self.up
    create_table :easy_helpdesk_mail_templates_mailboxes do |t|
      t.column :mail_template_id, :integer, {:null => false}
      t.column :mailbox_id, :integer, {:null => false}
    end
  end

  def self.down
    drop_table :easy_helpdesk_mail_templates_mailboxes
  end
end