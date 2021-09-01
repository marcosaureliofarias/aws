class AddDefaultToEasyHelpdeskMailTemplate < ActiveRecord::Migration[5.2]
  def change
    add_column :easy_helpdesk_mail_templates, :is_default, :boolean, default: false
  end
end
