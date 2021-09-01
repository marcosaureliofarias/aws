module ApiEasyUserWorkingTimeCalendarsHelper

  def render_api_easy_user_working_time_calendar(api, euwtc)
    api.easy_user_working_time_calendar do
      api.id(euwtc.id)
      api.name(euwtc.name)
      api.user_id(euwtc.user_id)
      api.parent_id(euwtc.parent_id)
      api.default_working_hours(euwtc.default_working_hours)
      api.first_day_of_week(euwtc.first_day_of_week)
      api.builtin(euwtc.builtin)
      api.is_default(euwtc.is_default)
      api.position(euwtc.position)
      api.time_from(format_time(euwtc.time_from, false))
      api.time_to(format_time(euwtc.time_to, false))
      api.working_week_days(euwtc.working_week_days)
      api.ical_url(euwtc.ical_url)
    end
  end

end
