require 'easy_quick_project_planner/easy_quick_project_planner'

ActiveSupport.on_load(:easyproject, yield: true) do

  require 'easy_quick_project_planner/hooks'

  Redmine::AccessControl.map do |map|
    map.project_module :quick_planner do |pmap|
      pmap.permission :quick_planner, {:easy_quick_project_planner => [:plan, :issues, :load_issues, :save_setting, :new_issue_row, :load_created_issue]}
    end
  end

end

# Redmine::MenuManager.map :project_menu do |menu|
#   menu.push :easy_quick_planner, { :controller => 'easy_quick_project_planner', :action => 'plan' }, :caption => :label_quick_planning, :if => Proc.new { |p| User.current.allowed_to?(:quick_planner, p) }
# end
