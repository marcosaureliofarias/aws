class AddReplyToToHelpdesk < ActiveRecord::Migration[4.2]

  def self.up

    add_column :easy_helpdesk_mail_templates, :reply_to, :string, {:null => true, :limit => 2048}

  end

  def self.down

  end
end