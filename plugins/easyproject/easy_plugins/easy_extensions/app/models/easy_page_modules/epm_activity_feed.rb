class EpmActivityFeed < EasyPageModule
  def category_name
    @category_name ||= 'others'
  end

  def permissions
    @permissions ||= [:view_project_activity]
  end

  def runtime_permissions(user)
    user.internal_client?
  end

  def get_show_data(settings, user, page_context = {})
    klass       = self.class
    events      = klass.events_for_settings(settings, user, page_context)
    row_limit   = klass.row_limit(settings)
    total_count = events.count

    { events: events.take(row_limit), total_count: total_count, current_limit: row_limit }
  end

  def get_edit_data(settings, _user, _page_context = {})
    author      = self.class.author(settings)
    project_ids = self.class.project_ids(settings)

    if project_ids.present?
      selected_projects = Project.where(id: project_ids).pluck(:id, :name).map { |id, name| { id: id, value: name } }
    end

    { author: author, selected_projects: selected_projects, available_global_filters: available_global_filters }
  end

  def self.event_types_for_settings(settings, user = User.current)
    scope = EasyActivity::ALL_SCOPE
    scope = settings['activity_scope'].first if settings['activity_scope']

    options                        = {}
    options[:selected_event_types] = settings['selected_event_types']
    options                        = EasyActivity.set_scope_for_options(scope, user, options)
    options[:selected_event_types].to_a
  end

  def self.events_for_settings(settings, user = nil, page_context = {})
    apply_global_filters!(page_context, settings)
    user        ||= User.current
    row_limit   = row_limit(settings)
    author      = author(settings)
    scope       = (settings['activity_scope'] && settings['activity_scope'].first) || EasyActivity::ALL_SCOPE
    project_ids = project_ids(settings)

    activity_options = { selected_event_types: settings['selected_event_types'] || [],
                         selected_projects:    project_ids,
                         custom_event_types:   settings['custom_event_types'],
                         author:               author,
                         limit:                row_limit }

    fetcher = EasyActivity.last_events_fetcher(user, nil, scope, activity_options)

    from, to = activity_date_range(author)
    events   = fetcher.easy_events(from, to, activity_options)
    events.group_by { |event| User.current.time_to_date(event.event_datetime) }
  end

  private

  class << self
    def row_limit(settings)
      row_limit = settings['row_limit'].to_i
      row_limit.between?(1, 50) ? row_limit : 10

      if settings['load_more']
        current_limit = settings['current_limit'].to_i
        row_limit     = current_limit.to_i.positive? ? current_limit + row_limit : row_limit * 2
      end

      row_limit
    end

    def author(settings)
      settings['author'] || (settings['author_id'].presence && User.find_by(id: settings['author_id']))
    end

    def project_ids(settings)
      settings['projects'].presence && Array(settings['projects']).select(&:presence).presence
    end

    def activity_date_range(author, days = nil)
      days ||= 7 # Use Setting.activity_days_default.to_i ?
      if author.blank?
        from = Date.today.advance(days: -days).beginning_of_day
        to   = Date.today.end_of_day
      end

      [from, to]
    end

    def apply_global_filters!(page_context, settings)
      return unless settings['global_filters'].is_a?(Hash)

      active_global_filters = page_context[:active_global_filters]
      return unless active_global_filters.is_a?(Hash) && active_global_filters.any?

      settings['global_filters'].each do |id, info|
        next unless (filter_value = active_global_filters[id])
        filter_name                = info['filter']
        settings[filter_name]      = filter_value
        settings['activity_scope'] = [EasyActivity::SELECTED_PROJECTS_SCOPE] if filter_name == 'projects'
      end
    end
  end

  def available_global_filters
    { user:    [{ name: l(:field_author), filter: 'author_id' }],
      project: [{ name: l(:field_project), filter: 'projects' }] }
  end
end
