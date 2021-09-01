class CreateHelpdeskMailTemplates < ActiveRecord::Migration[4.2]

  def self.up

    create_table :easy_helpdesk_mail_templates do |t|
      t.column :sender, :string, {:null => false, :limit => 2048}
      t.column :reply_to, :string, {:null => true, :limit => 2048}
      t.column :subject, :string, {:null => false, :limit => 2048}
      t.column :body_html, :text, {:null => true}
      t.column :body_plain, :text, {:null => true}

      t.column :issue_status_id, :integer, {:null => true}
    end

  end

  def self.down
    drop_table :easy_helpdesk_mail_templates
  end
end
