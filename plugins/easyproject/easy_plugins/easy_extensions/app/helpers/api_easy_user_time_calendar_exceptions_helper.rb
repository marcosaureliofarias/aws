module ApiEasyUserTimeCalendarExceptionsHelper

  def render_api_easy_user_time_calendar_exception(api, eutce)
    api.easy_user_time_calendar_exception do
      api.id(eutce.id)
      api.calendar_id(eutce.calendar_id)
      api.exception_date(eutce.exception_date)
      api.working_hours(eutce.working_hours)
    end
  end

end
