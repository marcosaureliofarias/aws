class AddEasyUniqIndexToEasyHostingPlugins < ActiveRecord::Migration[5.2]
  def up
    remove_index :easy_hosting_plugins, name: 'idx_ehp_plugin_name_1'
    add_easy_uniq_index :easy_hosting_plugins, [:plugin_name], name: 'idx_ehp_plugin_name_1'
  end
end
