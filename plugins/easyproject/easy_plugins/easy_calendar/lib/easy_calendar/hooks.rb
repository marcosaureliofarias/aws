module EasyCalendar
  class Hooks < Redmine::Hook::ViewListener

    include EasyExtensions::EasyAttributeFormatter

    render_on :view_settings_general_webdav, partial: 'settings/caldav'
    render_on :view_my_account_preferences, partial: 'external_calendars/easy_icalendars'
    # render_on :view_layout_top_tools, :partial => 'easy_calendar/upcoming_events'
    # render_on :view_layouts_base_html_head, :partial => 'easy_calendar/view_layouts_base_html_head'

  end
end
