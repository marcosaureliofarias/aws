module EasyExtensions
end

if Object.const_defined?(:RedmineExtensions) && RedmineExtensions.const_defined?(:PatchManager)
  EasyExtensions::PatchManager = RedmineExtensions::PatchManager
else
  raise 'redmine_extensions gem not found'
end
