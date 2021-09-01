class AddEmailToAndEmailCcToIssue < ActiveRecord::Migration[4.2]
  def change
    add_column :issues, :easy_email_to, :text, null: true
    add_column :issues, :easy_email_cc, :text, null: true
  end
end
