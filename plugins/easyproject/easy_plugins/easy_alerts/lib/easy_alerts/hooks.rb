module EasyAlerts
  class Hooks < Redmine::Hook::ViewListener

    render_on( :view_enumerations_list_bottom, :partial => 'alert_types/list')
    render_on( :view_easy_helpdesk_project_settings_bottom, :partial => 'easy_helpdesk_projects/alerts_box')

    def helper_options_for_default_project_page(context={})
      default_pages, enabled_modules = context[:default_pages], context[:enabled_modules]
      default_pages << 'easy_alerts' if enabled_modules && enabled_modules.include?('easy_alerts')
    end

  end
end
