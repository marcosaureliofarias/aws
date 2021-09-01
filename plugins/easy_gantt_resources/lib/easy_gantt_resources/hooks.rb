module EasyGanttResources
  class Hooks < Redmine::Hook::ViewListener
    render_on :view_easy_gantt_index_bottom, partial: 'hooks/easy_gantt_resources/view_easy_gantt_index_bottom'
    render_on :view_easy_gantt_resources_index_bottom, partial: 'hooks/easy_gantt_resources/view_easy_gantt_resources_index_bottom'
    render_on :view_easy_meeting_form_attributes_bottom, partial: 'hooks/easy_gantt_resources/view_easy_meeting_form_attributes_bottom'
    render_on :view_issues_form_details_bottom, partial: 'issues/easy_custom_resource_allocator'
    render_on :helper_render_api_user, partial: 'users/show_easy_gantt_resources_attributes'

    def view_issues_show_details_bottom(context={})
      return unless Rails.env.development?
      return if Setting.host_name != 'localhost:3000'

      context[:hook_caller].send(:render, partial: 'issues/show_resources_on_development', locals: context)
    end

    def model_project_gantt_reschedule(context={})
      EasyResourceBase.reschedule_issues(context[:all_issues], context[:days])
    end

    def controller_users_create_before_save(context = {})
      if context[:user] && context[:user].valid? && User.current.allowed_to_globally?(:manage_user_easy_gantt_resources)
        EasyGanttResources.user_easy_gantt_resource_attributes_from_params(context[:user], context[:hook_caller].params[:user])
      end
    end

  end
end
