if Redmine::Plugin.installed?(:easy_extensions)
  ActiveSupport.on_load(:easyproject, yield: true) do
    require 'easy_page_modules/epm_calculoid'
    EpmCalculoid.register_to_all
  end
  EasyExtensions::PatchManager.register_easy_page_helper 'EasyCalculoidHelper'
end
