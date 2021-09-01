# this block is executed once just after Redmine is started
# means after all plugins are initialized
# it is place for plain requires, not require_dependency
# it should contain hooks, permissions - base class in Redmine is required thus is not reloaded
ActiveSupport.on_load(:easyproject, yield: true) do
  require 'easy_resource_base/internals'
  require 'easy_resource_base/hooks'
end

# this block is called every time rails are reloading code
# in development it means after each change in observed file
# in production it means once just after server has started
# in this block should be used require_dependency, but only if necessary.
# better is to place a class in file named by rails naming convency and let it be loaded automatically
# Here goes query registering, custom fields registering and so on
RedmineExtensions::Reloader.to_prepare do

  if !Redmine::Plugin.registered_plugins[:easy_gantt]

    # A copy from easy_gantt/after_init.rb
    #
    Redmine::AccessControl.map do |map|
      map.project_module :easy_gantt do |pmap|
        # View global level
        pmap.permission(:view_global_easy_gantt, {
          easy_scheduler: [:index, :data],
        }, global: true, read: true)

        # Edit global level
        pmap.permission(:edit_global_easy_gantt, {
          easy_scheduler: [:save],
        }, global: true, require: :loggedin)

        # View personal level
        pmap.permission(:view_personal_easy_gantt, {
          easy_scheduler: [:personal, :data],
        }, global: true, read: true)

        # Edit personal level
        pmap.permission(:edit_personal_easy_gantt, {
          easy_scheduler: [:save],
        }, global: true, require: :loggedin)
      end
    end

  end

end
