class CreateEasyPrintableTemplates < ActiveRecord::Migration[4.2]
  def up
    create_table :easy_printable_templates, :force => true do |t|
      t.column :name, :string, {:null => false, :limit => 2048}
      t.column :project_id, :integer, {:null => true}
      t.column :author_id, :integer, {:null => false}
      t.column :private, :boolean, {:null => false, :default => false}
      t.column :pages_orientation, :string, {:null => false}
      t.column :pages_size, :string, {:null => false}
      t.timestamps
    end

    create_table :easy_printable_template_pages, :force => true do |t|
      t.column :easy_printable_template_id, :integer, {:null => false}
      t.column :page_text, :text, {:null => false}
      t.column :position, :integer, {:null => true, :default => 1}
      t.timestamps
    end

    add_index :easy_printable_template_pages, [:easy_printable_template_id], :name => 'idx_eptp_template_id'

  end

  def down
    drop_table :easy_printable_templates
    drop_table :easy_printable_template_pages
    begin
      FileUtils.rm_f(File.join(Rails.root, 'config', 'initializers', 'pdfkit.rb'))
    rescue StandardError => e
      say e.message
    end
  end
end
