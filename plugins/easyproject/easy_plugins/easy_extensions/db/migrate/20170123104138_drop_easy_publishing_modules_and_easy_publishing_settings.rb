class DropEasyPublishingModulesAndEasyPublishingSettings < ActiveRecord::Migration[4.2]

  def up
    drop_table :easy_publishing_modules if ActiveRecord::Base.connection.table_exists? :easy_publishing_modules
    drop_table :easy_publishing_settings if ActiveRecord::Base.connection.table_exists? :easy_publishing_settings
  end

end
