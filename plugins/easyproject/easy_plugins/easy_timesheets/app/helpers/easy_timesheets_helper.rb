module EasyTimesheetsHelper

  def render_timesheets_breadcrumb
    links = []
    links << link_to(l(:label_easy_timesheets), easy_timesheets_path)
    links << link_to(@easy_timesheet.user, easy_timesheets_path({:set_filter => 1, :user_id => @easy_timesheet.user_id})) if @easy_timesheet && @easy_timesheet.user
    links << link_to("#{format_date @easy_timesheet.start_date} - #{format_date @easy_timesheet.end_date}", {}) if @easy_timesheet

    breadcrumb links
  end

  def render_tfoot_updater
    @easy_timesheet.sum_row(true)
    return %Q($("#easy_timesheet_#{ @easy_timesheet.id }_sum_row").closest("tfoot").html("#{j render(:partial => 'easy_timesheets/footer', :locals => {:easy_timesheet => @easy_timesheet}) }");).html_safe
  end

end
