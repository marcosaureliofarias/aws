module EasyAgileBoardHelper

  def easy_sprint_assignee_options_for_select(assignees, options = {})
    assignee_options = []
    prompt = options.fetch(:prompt, '-')
    assignee_options << [prompt, nil] if options.fetch(:include_blank, false)
    assignee_options.concat assignees.sort_by {|a| a.to_s }.map {|a| [ a, a.id ] }
    options_for_select(assignee_options, options)
  end

  def easy_agile_issue_rating(issue, sprint_project_id)
    return unless easy_agile_issue_rating_enabled?(sprint_project_id)
    rating_mode = EasySetting.value('easy_agile_issue_rating_mode', sprint_project_id)
    issue_rating_key = issue_rating_key_by_mode(rating_mode, sprint_project_id)
    css_classes = "issue-rating #{rating_mode}"

    if issue_rating_key
      value = case rating_mode
      when 'value_from_custom_field'
        cf_id = EasySetting.value('easy_agile_issue_rating_cf', sprint_project_id)
        cfv = issue.custom_field_value_for(cf_id)
        formatted = format_easy_agile_issue_rating(show_value(cfv, true, {}))

        if cfv.nil?
          # CustomField or CustomValue does not exist
        else
          cfv.custom_field.format.formatted_with_inline_edit(self, cfv, formatted,
            { data: { id: issue.id, url: url_to_entity(issue, format: 'json'), name: issue_rating_key, key: issue_rating_key },
              css_class: " #{css_classes}"
            }
          )
        end
      when 'estimated_time'
        val = issue.easy_agile_rating
        formatted = format_easy_agile_issue_rating(val)
        css_classes << ' multieditable' if issue.editable? && issue.safe_attribute?('estimated_hours')
        content_tag(:span, formatted, class: css_classes, data: { id: issue.id, url: url_to_entity(issue, format: 'json'), name: issue_rating_key, type: 'hours', value: val, key: issue_rating_key })
      when 'story_points'
        css_classes << ' multieditable' if issue.editable? && issue.respond_to?(:safe_attribute?) && issue.safe_attribute?('easy_story_points')
        content_tag(:span, format_locale_number(issue.easy_story_points), class: css_classes, data: { id: issue.id, url: url_to_entity(issue, format: 'json'), name: issue_rating_key, value: issue.easy_story_points, type: 'text' })
      end
    end
    value ||= content_tag(:span, format_easy_agile_issue_rating(issue.easy_agile_rating), class: css_classes)
    value.html_safe
  end

  def format_easy_agile_issue_rating(value)
    '(' << (value.to_s.presence || '-') << ')'
  end

  def easy_agile_issue_rating_enabled?(sprint_project_id)
    EasySetting.value('easy_agile_issue_rating_mode', sprint_project_id) != 'disabled'
  end

  def issue_rating_key_by_mode(mode, sprint_project_id)
    case mode
    when 'estimated_time'
      'issue[estimated_hours]'
    when 'value_from_custom_field'
      "issue[custom_field_values][#{EasySetting.value('easy_agile_issue_rating_cf', sprint_project_id)}]"
    when 'story_points'
      'issue[easy_story_points]'
    end
  end

  def easy_agile_board_chart_tabs(project, easy_sprint)
    tabs = [
      { name: 'burndown', partial: 'easy_agile_board/charts/burndown', label: :label_easy_agile_board_chart_burndown, redirect_link: true, url: easy_agile_board_burndown_chart_path(project, sprint) }
    ]
    return tabs
  end

  def new_issue_tabs
    url = issues_new_for_dialog_path(modul_uniq_id: 'new_for_backlog', project_id: @project, issue: { easy_sprint_id: @easy_sprint })
    Array.wrap(name: 'new_issue', label: l(:label_issue_new), trigger: "EntityTabs.showAjaxTab(this, '#{url}')")
  end
end
