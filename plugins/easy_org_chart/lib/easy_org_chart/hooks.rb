module EasyOrgChart
  class Hooks < Redmine::Hook::ViewListener
    render_on :view_users_index_bottom_of_easy_page_layout_service_box, partial: 'hooks/view_users_index_bottom_of_easy_page_layout_service_box'
    render_on :view_users_form, :partial => 'hooks/view_users_form'

    def controller_easy_auto_complete_internal_users(context = {})
      additional_options = context[:additional_options]
      if context[:request].params[:include_peoples]&.include?('subordinates')
        User.add_my_subordinates_options(additional_options)
      end
    end

    def helper_render_api_user(context = {})
      context[:api].supervisor_user_id(context[:user].supervisor_user_id)
    end

    def controller_easy_auto_complete_principals(context = {})
      include_peoples = context[:request].params[:include_peoples]
      if include_peoples&.include?('subordinates')
        User.add_my_subordinates_options(context[:additional_options])
      end
    end

  end
end
