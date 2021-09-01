module EasyScheduler
  class Preparation

    attr_reader :settings, :active_query_klass, :user_preparation
    delegate :selected_principal_options, to: :user_preparation

    def initialize(settings)
      @settings = settings
      @active_query_klass = get_active_query_klass
      @user_preparation = EasyScheduler::UserPreparation.new(settings)
    end

    def query
      new_query = active_query_klass.new

      new_query.from_params(query_settings)
      new_query.easy_currency_code = settings['easy_currency_code'] if settings['easy_currency_code']
      new_query
    end

    def scheduler_settings
      new_settings = settings['scheduler_settings'] || {}

      new_settings['manager'] = (new_settings['scheduler_type'] == 'manager')
      new_settings['selected_user_ids'] = user_preparation.selected_principals.pluck(:id)
      new_settings['reload_assignees'] = user_preparation.need_to_reload_assignees? # need to reload assignees from settings

      if new_settings['range_type'] == 'automatic' && (working_calendar = User.current.current_working_time_calendar)
        new_settings['display_from'] = working_calendar.time_from&.strftime("%H:%M")
        new_settings['display_to'] = working_calendar.time_to&.strftime("%H:%M")
      end

      new_settings
    end

    def tagged_queries
      queries = EasySchedulerEasyQuery.tagged_queries(User.current, nil, ignore_admin: true)
      queries.each(&:set_sort_helper)
      queries.to_a
    end

    def get_active_query_klass
      query_class = settings.dig('query_settings', 'active_query_klass')&.safe_constantize || EasyScheduler.default_query
      return EasyScheduler.default_query unless EasyScheduler.registered_queries.include?(query_class)
      query_class
    end

    def query_settings
      return {} unless settings['query_settings'].is_a?(Hash)
      query_params = { 'set_filter' => '1' }
      if settings['query_settings']['active_query_klass'] == active_query_klass.name
        settings['query_settings'].merge(query_params)
      else
        query_params
      end
    end

    def icalendars
      return [] unless EasyScheduler.easy_calendar?
      EasyIcalendar.where(id: settings.dig('scheduler_settings', 'icalendars'))
    end
  end
end
