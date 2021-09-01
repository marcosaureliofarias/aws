module EasyScheduler
  class Hooks < Redmine::Hook::ViewListener
    def controller_easy_calendar_action_user_availability_before_map_events(context = {})
      user_id = context[:user].id

      if context[:hook_caller].params[:with_easy_entity_activities] && EasyScheduler.easy_entity_activities?
        allowed_entity_types = EasyEntityActivity.get_allowed_entity_types
        activities = if allowed_entity_types.empty?
                       []
                     else
                       ::EasyEntityActivity.user_activities(user_id, context[:start_date], context[:end_date]).where(entity_type: allowed_entity_types)
                     end
        context[:events].concat(activities.to_a)
      end

      if context[:hook_caller].params[:with_ical] && EasyScheduler.easy_calendar?
        if user_id == User.current.id
          ical_events = ::EasyIcalendarEvent.from_calendars(context[:hook_caller].params[:ical_ids]).between(context[:start_date], context[:end_date])
        else
          ical_events = ::EasyIcalendarEvent.user_events(user_id).between(context[:start_date], context[:end_date])
        end
        context[:events].concat(ical_events.to_a)
      end

      if context[:hook_caller].params[:with_custom_allocations]
        start_date = context[:start_date] || Date.today - 1.month
        resources = ::EasyGanttResource.preload(issue: :author).
          where(user_id: User.current.id, custom: true).
          where('date > ?', start_date)

        context[:events].concat(resources.to_a)
      end
    end

    def view_easy_query_form_options_bottom(context = {})
      query = context[:query]
      return unless query.is_a? EasySchedulerEasyQuery

      selected_values = Principal.where(id: query.settings['selected_principal_ids']).map do |principal|
        { id: principal.id, value: principal.name }
      end

      view_context = context[:hook_caller]
      principal_autocomplete = view_context.autocomplete_field_tag 'settings[selected_principal_ids][]',
                                                                   easy_autocomplete_path('principals', include_peoples: 'subordinates'),
                                                                   selected_values,
                                                                   rootElement: 'users',
                                                                   id: "#{context[:block_name]}_principal_ids",
                                                                   preload: false

      "<p><label>#{I18n.t('easy_scheduler.label_users_and_groups')}</label>#{principal_autocomplete}</p>".html_safe
    end

  end
end
