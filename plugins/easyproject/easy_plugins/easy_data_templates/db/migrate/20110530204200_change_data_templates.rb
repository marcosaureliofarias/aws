class ChangeDataTemplates < ActiveRecord::Migration[4.2]
  def self.up
    change_column :easy_data_templates, :entity_type, :string, { :null => true, :limit => 255 }

    add_column :easy_data_templates, :format_type, :string,  {:null => true, :limit => 255}

    EasyDataTemplate.reset_column_information
    EasyDataTemplate.update_all(:format_type => 'csv')

    change_column :easy_data_templates, :format_type, :string, { :null => false, :limit => 255 }
  end

  def self.down
  end
end
