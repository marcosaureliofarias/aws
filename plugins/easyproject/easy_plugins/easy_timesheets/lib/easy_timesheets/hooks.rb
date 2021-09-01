module EasyTimesheets
  class Hooks < Redmine::Hook::ViewListener

    render_on :view_timelog_index_additional_tabs, :partial => 'timelog/easy_timesheets_additional_tabs'

  end
end
