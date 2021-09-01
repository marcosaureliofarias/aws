module EasyBudgetsheet
  class Hooks < Redmine::Hook::ViewListener

    render_on :view_time_entries_user_time_entry_middle, :partial => 'timelog/easy_budgetsheet_view_time_entries_user_time_entry_middle'
    render_on :view_time_entries_context_menu_end, :partial => 'timelog/easy_budgetsheet_view_time_entries_context_menu_end'
    render_on :view_settings_timeentries_form, :partial => 'settings/easy_budgetsheet_view_settings_timeentries_form'
    render_on :view_sidebar_helpdesk_project_info_bottom, :partial => 'sidebar/easy_helpdesk_project_info_report_link'
    render_on :view_easy_helpdesk_sidebar_bottom, :partial => 'sidebar/easy_helpdesk_report_button'
    render_on :easy_invoicing_invoice_details_bottom, :partial => 'invoicing/time_entries_ids_for_invoicing'

    def helper_timelog_render_api_time_entry(context={})
      context[:api].easy_is_billable(context[:time_entry].easy_is_billable)
      context[:api].easy_billed(context[:time_entry].easy_billed)
    end
  end
end
