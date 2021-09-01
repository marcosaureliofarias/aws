class ChangeSettingsToJson < ActiveRecord::Migration[5.2]
  def up
    EasyExtensions::IvarsHelper.fix_ivars!(EasyEntityImport, :settings) if defined?(EasyExtensions)
    # change_column :easy_entity_imports, :settings, :json
  end

  def down

  end
end
