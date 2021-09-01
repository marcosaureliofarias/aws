module EasyCalculations
  class Hooks < Redmine::Hook::ViewListener
    render_on :view_projects_form_below_relations, :partial => 'easy_calculation/project_settings'
    render_on :view_issue_sidebar_issue_buttons, :partial => 'issues/easy_calculation_add_to_easy_calculations'
    render_on :easy_contacts_toolbar_assignable_entities_bottom, partial: 'easy_contacts_toolbar/register_easy_calculation_project_client'

    def model_project_copy_additionals(context={})
      context[:to_be_copied] << 'easy_calculation'
    end

    def helper_options_for_default_project_page(context={})
      default_pages, enabled_modules = context[:default_pages], context[:enabled_modules]
      default_pages << 'easy_calculation' if enabled_modules && enabled_modules.include?('easy_calculation')
    end
  end
end
