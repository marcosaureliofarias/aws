class IvarsExtensionsModules < EasyExtensions::EasyDataMigration
  def up
    require_relative '../../lib/easy_extensions/ivars_helper'
    EasyExtensions::IvarsHelper.convert_to_json(EasyPageZoneModule, [:settings])
    EasyExtensions::IvarsHelper.convert_to_json(EasyPageTemplateModule, [:settings])
  end

  def down
  end
end
