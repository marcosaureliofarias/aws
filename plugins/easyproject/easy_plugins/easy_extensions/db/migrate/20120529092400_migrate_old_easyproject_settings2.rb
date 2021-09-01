class MigrateOldEasyprojectSettings2 < ActiveRecord::Migration[4.2]
  def self.up
    Setting.where(name: 'plugin_easyproject').update_all(name: 'plugin_easy_extensions')
  end

  def self.down
    Setting.where(name: 'plugin_easy_extensions').update_all(name: 'plugin_easyproject')
  end
end
