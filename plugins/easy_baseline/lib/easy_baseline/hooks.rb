module EasyBaseline
  class Hooks < Redmine::Hook::ViewListener

    def model_project_copy_before_save(context = {})
      context[:destination_project].status = Project::STATUS_ARCHIVED if context[:destination_project].easy_baseline_for_id
    end

    def controller_admin_projects(context = {})
      context[:query].add_additional_scope(Project.no_baselines)
    end
  end
end
