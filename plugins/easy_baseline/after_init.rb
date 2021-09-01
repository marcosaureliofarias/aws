# this block is runed once just after easyproject is started
# means after all plugins(easy) are initialized
# it is place for plain requires, not require_dependency
# it should contain hooks, permissions - base class in redmine is required thus is not reloaded
ActiveSupport.on_load(:easyproject, yield: true) do
  require 'easy_baseline/internals'
  require 'easy_baseline/hooks'

  Redmine::AccessControl.map do |map|
    map.project_module :easy_baselines do |pmap|
      pmap.permission :view_baselines, {
        easy_baselines: [:index, :show],
        easy_baseline_gantt: [:show]
      }
      pmap.permission :edit_baselines, {
        easy_baselines: [:create, :destroy, :new]
      }
    end
  end

end
