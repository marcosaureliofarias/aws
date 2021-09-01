class EpmIssuesCreateNew < EpmEntityCreateNew

  def category_name
    @category_name ||= 'issues'
  end

  def permissions
    @permissions ||= [:add_issues]
  end

  def entity
    Issue
  end

  def get_show_data(settings, user, page_context = {})
    fields                         = (settings['selected_fields'] ||= {})
    settings['show_fields_option'] ||= 'all'
    issue                          = page_context[:issue] || entity.new
    unless page_context[:issue]
      if settings['show_fields_option'] == 'only_selected' && fields['project_id'] && fields['project_id']['default_value'].present?
        issue.project = Project.visible(user).has_module(:issue_tracking).allowed_to(:add_issues).find_by(id: fields['project_id']['default_value'])
        issue.project ||= last_project(user) if fields['project_id']['enabled']
      else
        issue.project = last_project(user)
      end
    end

    if issue.project
      allowed_trackers = issue.allowed_target_trackers
      if fields[:tracker_id] && fields[:tracker_id]['default_value'].is_a?(Array) && fields[:tracker_id]['default_value'].length > 1
        allowed_trackers.to_a.select! { |t| fields[:tracker_id]['default_value'].include?(t.id.to_s) }
      end
    end

    unless page_context[:issue]
      issue.tracker    = allowed_trackers&.first
      issue.start_date ||= Date.today
      issue.author     = user
    end
    issue_priorities = IssuePriority.active
    assignable_users = issue.assignable_users
    allowed_statuses = issue.new_statuses_allowed_to(user)

    issue_default_values_from_settings(issue, fields, settings, assignable_users, issue_priorities, allowed_statuses) unless page_context[:issue]

    unless allowed_statuses.include?(issue.status)
      issue.status = allowed_statuses.first
    end

    hidden_fields          = []
    required_attributes    = []
    shown_custom_field_ids = []
    if settings['show_fields_option'] == 'only_selected'
      hidden_fields = Array(settings['selected_fields']).select { |f| f[1].is_a?(Hash) && !f[1]['enabled'] }.collect { |f| f[0].to_sym }

      cf_ids = fields.keys & visible_entity_custom_field_values.map { |cfv| cfv.custom_field.id.to_s }
      cf_ids.each do |cf_id|
        shown_custom_field_ids << cf_id if fields[cf_id]['enabled']
      end

      show_watchers = fields.dig(:watchers, 'enabled').to_boolean && issue.project && user.allowed_to?(:add_issue_watchers, issue.project)
    elsif settings['show_fields_option'] == 'only_required'
      required_attributes = issue.required_attribute_names
      [:assigned_to_id, :due_date, :attachments].each do |field_to_hide|
        hidden_fields << field_to_hide if required_attributes.exclude?(field_to_hide.to_s)
      end
      hidden_fields << :category if required_attributes.exclude?('category_id')
      hidden_fields << :easy_is_repeating
      hidden_fields << :easy_issue_timer
      shown_custom_field_ids = required_entity_custom_field_ids
    end

    { issue:               issue, settings: settings, user: user, issue_priorities: issue_priorities,
      assignable_users:    assignable_users, allowed_statuses: allowed_statuses, shown_custom_field_ids: shown_custom_field_ids,
      hidden_fields:       hidden_fields, allowed_trackers: allowed_trackers, only_selected: settings['show_fields_option'] == 'only_selected',
      required_attributes: required_attributes, custom_field_values: settings['selected_fields']['custom_field_values'] || {},
      show_watchers: show_watchers, available_watchers: available_watchers(issue, fields, show_watchers) }
  end

  def available_fields
    {
        subject:           {},
        description:       {},
        project_id:        { label: :field_project },
        tracker_id:        { label: :field_tracker, values: Tracker.all },
        assigned_to_id:    { label: :field_assigned_to, values: all_principals },
        priority_id:       { label: :field_priority, values: IssuePriority.all },
        status_id:         { label: :field_status, values: IssueStatus.all },
        parent_issue_id:   { label: :field_parent_issue },
        start_date:        {},
        due_date:          {},
        estimated_hours:   {},
        easy_is_repeating: {},
        easy_issue_timer:  { label: :field_easy_issue_timer_start_now },
        category:          {},
        easy_email_to:     {},
        easy_email_cc:     {},
        attachments:       {},
        watchers:          { label: :label_issue_watchers, values: all_principals }
    }
  end

  private

  def last_project(user)
    last_issue = Issue.visible.where(author_id: user.id).reorder("#{Issue.table_name}.id DESC").first
    last_issue&.project || Project.visible(user).non_templates.sorted.has_module(:issue_tracking).allowed_to(:add_issues).first
  end

  def issue_default_values_from_settings(issue, fields, settings, assignable_users, allowed_priorities, allowed_statuses)
    return if fields.blank? || settings['show_fields_option'] != 'only_selected'

    enabled_normal_fields = ['subject', 'description', 'start_date', 'due_date', 'easy_is_repeating', 'easy_email_to', 'easy_email_cc']
    enabled_id_values     = {
        'tracker_id'     => issue.project&.tracker_ids || [],
        'assigned_to_id' => assignable_users.collect(&:id),
        'priority_id'    => allowed_priorities.collect(&:id),
        'status_id'      => allowed_statuses.collect(&:id)
    }

    fields.each do |name, options|
      if enabled_normal_fields.include?(name)
        issue.send("#{name}=", options['default_value']) if options['default_value'].present?
      elsif issue.project && enabled_id_values.key?(name)
        value_id = options['default_value'].presence
        value_id = (name == 'tracker_id' ? value_id.first.to_i : value_id.to_i) if value_id
        issue.send("#{name}=", value_id) if enabled_id_values[name].include?(value_id)
      end
    end
  end

  def available_watchers(issue, fields, show_watchers = true)
    return {} if !show_watchers
    available_watcher_groups = issue.available_groups
    available_watcher_users = issue.addable_watcher_users
    selected_watcher_ids = Array.wrap(fields[:watchers]['default_value'].presence).map(&:to_i)
    issue.watcher_principal_ids = selected_watcher_ids & (available_watcher_groups + available_watcher_users).map(&:id)
    { available_watcher_groups: available_watcher_groups, available_watcher_users: available_watcher_users}
  end

end
