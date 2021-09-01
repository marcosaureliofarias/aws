class AddEasyPageModuleType < ActiveRecord::Migration[4.2]
  def self.up

    add_column :easy_page_modules, :type, :string, :null => true

    EasyPageModule.reset_column_information

    EasyPageModule.connection.select_all("SELECT id, module_name FROM #{EasyPageModule.table_name}").each do |row|
      new_name = ('epm_' + row['module_name']).camelize
      EasyPageModule.where(:id => row['id']).update_all(:type => new_name)
    end

    remove_columns :easy_page_modules, :module_name, :category_name, :view_path, :edit_path, :default_settings, :permissions

  end

  def self.down

  end

end
