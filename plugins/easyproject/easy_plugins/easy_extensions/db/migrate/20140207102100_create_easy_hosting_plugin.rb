class CreateEasyHostingPlugin < ActiveRecord::Migration[4.2]
  def self.up
    return if table_exists?(:easy_hosting_plugins)

    create_table :easy_hosting_plugins do |t|
      t.column :plugin_name, :string, { :null => false, :limit => 255 }
      t.column :activated, :boolean, { :null => false, :default => false }
      t.column :activated_by, :integer, { :null => true }
      t.column :activated_to, :datetime, { :null => true }
      t.column :trial_count, :integer, { :null => false, :default => 0 }
      t.timestamps
    end

    add_index :easy_hosting_plugins, [:plugin_name], :name => 'idx_ehp_plugin_name_1'
    add_index :easy_hosting_plugins, [:activated], :name => 'idx_ehp_plugin_name_2'

    EasyHostingPlugin.transaction do
      EasyHostingPlugin.available_plugins.each do |plugin|
        EasyHostingPlugin.create(plugin_name: plugin, activated: true, activated_by: nil, activated_to: nil, trial_count: 0)
      end
    end

  end

  def self.down
    drop_table :easy_hosting_plugins
  end

end
