class AddEmailFooterToHelpdeskProject < ActiveRecord::Migration[4.2]

  def self.up
    add_column :easy_helpdesk_projects, :email_header, :text, {:null => true}
    add_column :easy_helpdesk_projects, :email_footer, :text, {:null => true}
  end

  def self.down
    remove_column :easy_helpdesk_projects, :email_header
    remove_column :easy_helpdesk_projects, :email_footer
  end
end