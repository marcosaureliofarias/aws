class RemoveSenderAndReplyTo < ActiveRecord::Migration[4.2]

  def self.up
    remove_column :easy_helpdesk_mail_templates, :sender, :reply_to
  end

  def self.down
  end
end