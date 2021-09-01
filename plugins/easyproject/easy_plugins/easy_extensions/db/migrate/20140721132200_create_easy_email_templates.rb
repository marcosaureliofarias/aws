class CreateEasyEmailTemplates < ActiveRecord::Migration[4.2]

  def up
    create_table :easy_email_templates do |t|
      t.column :type, :string, null: false
      t.column :name, :string, null: false
      t.column :internal_name, :string
      t.column :subject, :string, null: false
      t.column :body_html, :text
      t.column :body_plain, :text
    end
  end

  def down
    drop_table :easy_email_templates
  end

end
