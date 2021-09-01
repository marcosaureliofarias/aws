module EasyQuickProjectPlanner
  class Hooks < Redmine::Hook::ViewListener

    render_on :view_projects_show_bottom, :partial => 'easy_quick_project_planner/project_button'

    def helper_project_settings_tabs(context={})
      if User.current.allowed_to?(:quick_planner, context[:project])
        context[:tabs] << {:name => 'quick_planner', :action => :quick_planner, :partial => 'projects/settings/easy_quick_project_planner', :label => :label_quick_planning}
      end
    end

    def controller_templates_create_project_from_template(context={})
      if context[:params][:template]# && context[:params][:template][:inherit_easy_quick_planner_settings]
        context[:saved_projects].each do |p|
          EasySetting.copy_project_settings(:quick_planner_fields, context[:source_project], p)
        end
      end
    end

  end
end
