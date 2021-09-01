class DestroyEntityTypeAtEasyDataTemplates < ActiveRecord::Migration[4.2]
  def self.up
    remove_column :easy_data_templates, :entity_type
  end

  def self.down
  end
end
