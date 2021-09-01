app_dir = File.join(File.dirname(__FILE__), 'app')

# Others
ActiveSupport::Dependencies.autoload_paths << File.join(app_dir, 'models', 'easy_page_modules')

EasyExtensions::PatchManager.register_easy_page_helper 'EasyEarnedValuesHelper'
EpmEasyEarnedValue.register_to_all

Redmine::MenuManager.map :project_menu do |menu|
  menu.push(:easy_earned_values, { controller: 'easy_earned_values', action: 'index' },
    param: :project_id,
    caption: :label_easy_earned_values,
    if: proc { |p| User.current.allowed_to?(:view_easy_earned_values, p) })
end

Redmine::AccessControl.map do |map|
  map.project_module :easy_earned_values do |pmap|
    pmap.permission(:view_easy_earned_values, {
      easy_earned_values: [:index, :show]
    }, read: true)

    pmap.permission(:edit_easy_earned_values, {
      easy_earned_values: [:new, :edit, :create, :update, :destroy]
    }, require: :member)
  end
end

# this block is called every time rails are reloading code
# in development it means after each change in observed file
# in production it means once just after server has started
# in this block should be used require_dependency, but only if necessary.
# better is to place a class in file named by rails naming convency and let it be loaded automatically
# Here goes query registering, custom fields registering and so on
RedmineExtensions::Reloader.to_prepare do
  require 'easy_earned_values/internals'
  require 'easy_earned_values/hooks'
end
