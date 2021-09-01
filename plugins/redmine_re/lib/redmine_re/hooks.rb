module RedmineRe

  module Hooks
    class ViewIssuesHook < Redmine::Hook::ViewListener
      render_on :view_layouts_base_body_bottom, :partial => 'requirements/body_bottom'
      render_on :view_issues_show_description_bottom, :partial => 'issues/show_related_artifacts'
      render_on :view_issues_form_details_bottom, :partial => 'issues/autocomplete_artifacts'

      # Artifacts Submenu in Issues Context Menu
      render_on :view_issues_context_menu_end, :partial => 'issues/artifacts_context_menu'
      render_on :view_issues_index_bottom, :partial => 'issues/re_stylesheets'

      def model_project_copy_additionals(context={})
        context[:to_be_copied] << 'requirements'
      end
    end
  end

end