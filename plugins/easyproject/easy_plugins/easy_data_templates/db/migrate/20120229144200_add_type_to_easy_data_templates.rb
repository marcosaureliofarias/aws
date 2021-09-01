class AddTypeToEasyDataTemplates < ActiveRecord::Migration[4.2]
  def self.up
    add_column :easy_data_templates, :type, :string, {:null => false}
  end

  def self.down
  end
end
