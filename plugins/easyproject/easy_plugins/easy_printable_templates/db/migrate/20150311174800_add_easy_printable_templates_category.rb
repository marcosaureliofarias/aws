class AddEasyPrintableTemplatesCategory < ActiveRecord::Migration[4.2]

  def self.up
    add_column :easy_printable_templates, :category, :string, {:null => false, :default => 'custom', :limit => 255}
    add_column :easy_printable_templates, :internal_name, :string, {:null => true, :limit => 255}

    add_index :easy_printable_templates, [:internal_name], :name => 'idx_ept_internal_name'
    add_index :easy_printable_templates, [:category], :name => 'idx_ept_category'
  end

  def self.down
  end
end