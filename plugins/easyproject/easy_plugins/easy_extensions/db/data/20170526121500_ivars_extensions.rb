class IvarsExtensions < EasyExtensions::EasyDataMigration
  def up
    require_relative '../../lib/easy_extensions/ivars_helper'
    EasyExtensions::IvarsHelper.convert_to_json(EasyQuery, [:filters, :custom_formatting, :settings, :chart_settings])
    EasyExtensions::IvarsHelper.convert_to_json(CustomField, [:settings])
    EasyExtensions::IvarsHelper.convert_to_json(EasyRakeTask, [:settings])
    EasyExtensions::IvarsHelper.convert_to_json(EasyRakeTaskInfo, [:options])
  end

  def down
  end
end
