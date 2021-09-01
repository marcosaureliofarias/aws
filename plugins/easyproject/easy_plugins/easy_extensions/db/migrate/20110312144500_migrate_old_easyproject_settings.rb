class MigrateOldEasyprojectSettings < ActiveRecord::Migration[4.2]
  def self.up
    Setting.where(name: 'plugin_easy_plugin').update_all(name: 'plugin_easyproject') if !Setting.find_by_name('plugin_easyproject')
  end

  def self.down
    Setting.where(name: 'plugin_easyproject').update_all(name: 'plugin_easy_plugin') if !Setting.find_by_name('plugin_easy_plugin')
  end

end
