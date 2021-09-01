module EasySchedulerHelper

  # This method exist because
  #   1. EntityAttributeHelper is for complex html formating
  #   2. Redmine doest not have it
  # Gantt should show light and non-html values
  # def gantt_format_column(entity, column, value)
  #   if entity.is_a?(Project) && column.name == :status && respond_to?(:format_project_attribute)
  #     format_project_attribute(Project, column, value)
  #   elsif value.is_a?(Float)
  #     locale = User.current.language.presence || ::I18n.locale
  #     number_with_precision(value, locale: locale).to_s
  #   else
  #     value.to_s
  #   end
  # end

  def calendar_avatar_url(user)
    if defined?(avatar_url)
      avatar_url(user)
    elsif Setting.gravatar_enabled?
      gravatar_url(user.mail.to_s.downcase, size: 64, default: Setting.gravatar_default)
    else
      ''
    end
  end

  def javascript_include_tag_safe(*sources)
    javascript_include_tag(*sources.compact)
  end

  def scheduler_api_render_users(api, users, options = {})
    # with_rm = EasyScheduler.easy_gantt_resources?
    api.array :users do
      users.each do |user|
        api.user do
          api.id user.id
          api.name user.name
          api.avatar_url calendar_avatar_url(user)
          api.working_days EasyScheduler.working_week_days(user)
          # if with_rm
          #   TODO improve scheduler to use settings from RM if RM present
          #   api.week_hours EasyGanttResource.hours_on_week(user)
          #   api.estimated_ratio EasyGanttResource.estimated_ratio(user)
          # end
          if options[:with_working_time] && (calendar = user.current_working_time_calendar)
            api.start_time calendar.time_from ? calendar.time_from.seconds_since_midnight.in_milliseconds : nil
            api.end_time calendar.time_to ? calendar.time_to.seconds_since_midnight.in_milliseconds : nil
          end
        end
      end
    end
  end

  def scheduler_api_render_allocations(api, allocations, _options = {})
    api.array :allocations do
      allocations.each do |allocation|
        api.resource do
          api.id allocation.id
          api.issue_id allocation.issue_id
          api.user_id allocation.user_id
          api.hours allocation.hours
          api.custom allocation.custom
          api.date allocation.date
          api.full_date allocation.full_date
        end
      end
    end
  end

  def scheduler_api_render_issues(api, issues, options = {})
    api.array :issues do
      issues.each do |issue|
        api.issue do
          api.id issue.id
          api.project_id issue.project_id
          api.subject issue.subject
          api.assigned_to_id issue.assigned_to_id
          api.estimated_hours issue.estimated_hours
          api.spent_hours issue.spent_hours
          api.start_date issue.start_date
          api.due_date issue.due_date
          api.scheme issue.css_scheme
          api.author_id issue.author_id

          if options[:additional_info]
            api.possible_assignee_ids issue.project.members.map(&:user_id)
            api.custom_allocated_hours issue.custom_allocated_hours
            api.status issue.status
            api.priority issue.priority
            api.tracker issue.tracker
            api.fixed_version issue.fixed_version
            api.project { api.name issue.project.name }
            api.unread issue.unread?
          end

          if @included_in_query_issue_ids
            api.included_in_query @included_in_query_issue_ids.include?(issue.id)
          end

          api.permissions do
            api.editable issue.resource_editable?
            api.editable_estimated_hours issue.safe_attribute?('estimated_hours')
            api.viewable_estimated_hours User.current.allowed_to?(:view_estimated_hours, issue.project)
          end
        end
      end
    end
  end

  def scheduler_api_render_easy_crm_cases(api, crm_cases, options = {})
    api.array :crm_cases do
      crm_cases.each do |crm_case|
        currency = options[:currency] || crm_case.currency
        api.crm_case do
          api.id crm_case.id
          api.project_id crm_case.project_id
          api.name crm_case.name
          api.assigned_to_id crm_case.assigned_to_id
          api.contract_date crm_case.contract_date
          api.next_action crm_case.next_action
          api.currency currency
          api.price crm_case.price(currency)
          api.scheme crm_case.css_classes.split(' scheme ')[1]

          api.permissions do
            api.editable crm_case.editable?
          end

          if options[:additional_info]
            api.possible_assignee_ids crm_case.project.members.map(&:user_id)
            api.project { api.name crm_case.project.name }
            api.currency_symbol EasyCurrency.get_symbol(currency)
          end
        end
      end
    end
  end


end
