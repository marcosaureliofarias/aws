class EasyActivity

  INVISIBLE_EVENT_TYPES = ['changesets', 'easy_attendances']

  ALL_SCOPE               = 'all'
  SELECTED_ACTIVITY_SCOPE = 'selected_event_types'
  SELECTED_PROJECTS_SCOPE = 'selected_projects'

  def self.set_scope_for_options(scope, user = User.current, options = {})
    scope ||= ALL_SCOPE
    case scope
    when ALL_SCOPE
      options[:selected_event_types] = all_visible_event_types(user) unless options[:custom_event_types]
      options[:selected_projects]    = nil
    when SELECTED_PROJECTS_SCOPE
      options[:selected_event_types] = all_visible_event_types(user) unless options[:custom_event_types]
    when SELECTED_ACTIVITY_SCOPE
      options[:selected_projects] = nil
    end

    options
  end

  # selected_event_types = ["issues", "changesets", "news", "documents", "files"]
  def self.last_events_fetcher(user, project, scope = nil, options = {})
    options = set_scope_for_options(scope, user, options) if scope

    permitted_keys = %i[with_subprojects author user display_updated display_read]

    activity_options               = options.select { |key, _value| permitted_keys.include? key }
    activity_options[:project]     = project
    activity_options[:project_ids] = options[:selected_projects]

    activity       = Redmine::Activity::Fetcher.new(user, activity_options)
    activity.scope = options[:selected_event_types]
    activity
  end

  def self.last_events_range(user, **options)
    today = user.today
    uwtc  = user.current_working_time_calendar

    shift_days = options[:last_x_days].to_i
    shift_days = 30 if shift_days.abs > 30 # max limit
    shift_days = -shift_days if shift_days.positive? # ensure negative number

    event_start_date = if uwtc
                         uwtc.shift_working_day(shift_days - 1, today).beginning_of_day
                       else
                         today.advance(days: shift_days).beginning_of_day
                       end

    [event_start_date, today.end_of_day]
  end

  def self.last_events(user, project, scope = nil, options = {})
    activity                         = self.last_events_fetcher(user, project, scope, options)
    event_start_date, event_end_date = last_events_range(user, options)
    activity.easy_events(event_start_date, event_end_date, options)
  end

  def self.last_events_count(user, project, scope = nil, options = {})
    activity                         = self.last_events_fetcher(user, project, scope, options)
    event_start_date, event_end_date = last_events_range(user)
    activity.easy_events_count(event_start_date, event_end_date, options.merge(limit: nil))
  end

  def self.last_current_user_events_with_defaults(**options)
    options = {
      with_subprojects: false,
      user: User.current,
      display_updated: true
    }.merge(options)


    EasyActivity.last_events(User.current, nil, ALL_SCOPE, options)
  end

  def self.last_current_user_events_with_defaults_count
    options = {
        :with_subprojects => false,
        :user             => User.current,
        :display_updated  => true
    }

    EasyActivity.last_events_count(User.current, nil, ALL_SCOPE, options)
  end

  def self.all_event_types(user)
    Redmine::Activity::Fetcher.new(user || User.current).event_types
  end

  def self.all_visible_event_types(user)
    all_event_types(user) - INVISIBLE_EVENT_TYPES
  end

end
