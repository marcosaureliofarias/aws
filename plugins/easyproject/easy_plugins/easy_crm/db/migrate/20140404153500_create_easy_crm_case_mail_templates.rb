class CreateEasyCrmCaseMailTemplates < ActiveRecord::Migration[4.2]

  def self.up

    create_table :easy_crm_case_mail_templates do |t|
      t.column :project_id, :integer, {:null => false}
      t.column :easy_crm_case_status_id, :integer, {:null => true}
      t.column :subject, :string, {:null => false, :limit => 2048}
      t.column :body_html, :text, {:null => true}
      t.column :body_plain, :text, {:null => true}
    end

  end

  def self.down
    drop_table :easy_crm_case_mail_templates
  end
end