class AddNameToEasyHelpdeskMailTemplates < ActiveRecord::Migration[4.2]
  def change
    add_column :easy_helpdesk_mail_templates, :name, :string, null: false, default: ""
  end
end
