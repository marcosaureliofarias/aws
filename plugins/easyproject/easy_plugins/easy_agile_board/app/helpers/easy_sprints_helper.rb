module EasySprintsHelper

  def easy_sprint_title(easy_sprint)
    title_classes = 'agile__sprint-title'
    title_classes << ' closed' if easy_sprint.closed?
    r = "<span class=\"#{title_classes}\">"
    r << h("#{easy_sprint.name} ")
    r << '</span>'
    r << easy_sprints_listing(easy_sprint)
    r << '<span class="agile__sprint-title-date">'
    r << format_date(easy_sprint.start_date)
    r << " - #{format_date(easy_sprint.due_date)}" if easy_sprint.due_date.present?
    r << '</span>'
    r.html_safe
  end

  def easy_sprints_listing(easy_sprint)
    r = ''
    r << link_to('', easy_agile_board_path(easy_sprint.project_id, sprint_id: easy_sprint.previous_easy_sprint), class: 'prev') if easy_sprint.previous_easy_sprint.present?
    r << link_to('', easy_agile_board_path(easy_sprint.project_id, sprint_id: easy_sprint.next_easy_sprint), class: 'next') if easy_sprint.next_easy_sprint.present?
    r.html_safe
  end

  def easy_sprint_head(project, easy_sprint, options={})
    s = '<div class="easy_sprint_heading agile__sprint-heading" style="text-align: center;">'
    s << '<div class="easy-query-listing-links next-prev-links" style="display: inline;">'
    s << easy_sprint_title(easy_sprint)
    if User.current.allowed_to?(:edit_easy_scrum_board, project)
      s << '<span class="scrum-actions agile__sprint-actions">'
      s << link_to('', edit_project_easy_sprint_path(project, easy_sprint), title: l(:title_edit_sprint), class: 'icon icon-edit')

      if easy_sprint.open?
        s << link_to('', close_dialog_project_easy_sprint_path(project, easy_sprint), class: 'icon icon-lock', title: l(:label_easy_agile_sprint_close), remote: true)
      else
        s << link_to('', open_project_easy_sprint_path(project, easy_sprint), class: 'icon icon-unlock', title: l(:label_easy_agile_sprint_open), method: :post, remote: true)
      end

      s << link_to('', project_easy_sprint_path(project, easy_sprint), method: :delete, data: { confirm: l(:text_are_you_sure) }, class: 'icon icon-del', title: l(:button_delete_sprint))
      s << '</span>'
    end
    s << '</div>'
    s << '</div>'
    s.html_safe
  end

  def easy_sprint_heading(sprint, options={})
    statuses = sprint.statuses_setting
    in_progress_setting = statuses[IssueEasySprintRelation::TYPE_PROGRESS]

    sprint_backlog = ActiveSupport::SafeBuffer.new
    sprint_backlog << l(:label_agile_backlog)

    sprint_backlog << link_to('',
        easy_agile_board_reorder_sprint_backlog_path(sprint.project_id,
          sprint_id: sprint,
          by: 'priority',
          back_url: easy_agile_board_path(sprint.project_id, sprint_id: sprint)),
        class: 'reorder-backlog icon icon-bullet-list',
        title: l(:title_reorder_sprint_backlog)
      )

    if easy_agile_issue_rating_enabled?(sprint.project_id)
      sear = sprint.sum_easy_agile_rating
      percent = (sear / sprint.capacity.to_f * 100) if sprint.capacity > 0
      percent ||= 0

      sprint_backlog << '<br>'.html_safe
      sprint_backlog << "<span title=\"#{j l(:label_agile_fullness)}\">".html_safe
      sprint_backlog << content_tag(:span, format_number(percent, '%d%%' % percent, no_html: true), class: 'easy-agile-rating')
      sprint_backlog << " (#{sear.round(1)} / "
      sprint_backlog << content_tag(:span, sprint.capacity, { class: 'multieditable', data: {
            name: 'easy_sprint[capacity]',
            type: 'text',
            value: sprint.capacity
          } })
      sprint_backlog << ')'
      sprint_backlog << '</span>'.html_safe
    end



    heading = ActiveSupport::SafeBuffer.new
    heading << content_tag(:th, sprint_backlog, rowspan: 2)
    heading << content_tag(:th, '', rowspan: 2, class: 'swimlane_worker') if options[:swimlane]
    heading << content_tag(:th, l(:label_agile_in_progress), colspan: in_progress_setting.keys.count) unless in_progress_setting.nil?
    heading << content_tag(:th, l(:label_agile_done), rowspan: 2)

    content_tag(:tr, heading) + content_tag(:tr) do
      in_progress_setting.each do |position, setting|
        concat content_tag(:th, setting['name'], data: { position: position, status: setting['status_id'] })
      end unless in_progress_setting.nil?
    end
  end

  def easy_sprint_columns(sprint, options={})
    relation_types = IssueEasySprintRelation::TYPES.dup
    relation_types.delete(IssueEasySprintRelation::TYPE_BACKLOG) if options[:no_backlog]
    relation_types.delete(IssueEasySprintRelation::TYPE_PROGRESS) if options[:no_progress]
    relation_types.delete(IssueEasySprintRelation::TYPE_DONE) if options[:no_done]

    done_relation = IssueEasySprintRelation::TYPES[:done]

    relations_scope = sprint.issue_easy_sprint_relations.
      preload(issue: [:status, :priority, :tracker, project: [:project_custom_fields, :custom_values, :enabled_modules], assigned_to: [Setting.gravatar_enabled? ? {} : :easy_avatar]])

    if sprint.display_closed_tasks_in_last_n_days.present?
      issues = Issue.arel_table
      issue_easy_sprint_relations = IssueEasySprintRelation.arel_table
      end_datetime = sprint.current_time_for_display_closed_tasks_in_last_n_days
      date_range = {from: end_datetime.beginning_of_day - sprint.display_closed_tasks_in_last_n_days.days, to: end_datetime }

      relations_scope = relations_scope.joins(:issue).
        where(
          issue_easy_sprint_relations[:relation_type].in(relation_types.values - [done_relation]).or(
            issue_easy_sprint_relations[:relation_type].eq(done_relation).and(
                issues[:closed_on].eq(nil).or(
                  issues[:closed_on].gt(date_range[:from]).and(
                  issues[:closed_on].lteq(date_range[:to])
                )
              )
            )
          )
        )
    else
      relations_scope = relations_scope.where(relation_type: relation_types.values)
    end

    if assigned_to_id = (params[:assigned_to_id] || options[:assigned_to_id])
      relations_scope = relations_scope.joins(:issue).where(issues: { assigned_to_id: assigned_to_id })
    elsif options.key?(:assigned_to_id) && options[:assigned_to_id].nil?
      relations_scope = relations_scope.joins(:issue).where(issues: { assigned_to_id: nil })
    end

    relations = relations_scope.group_by(&:relation_type)

    relation_types.each do |relation_type, value|
      rel_hash = relations[value].group_by(&:relation_position) if relations[value]
      rel_hash ||= {}
      positions = sprint.positions_for_type(relation_type)
      positions = [positions] unless positions.is_a?(Array) # nil becomes [nil]

      positions.each do |relation_position|
        issues = (rel_hash[relation_position] || []).inject([]){|mem,var| mem << var.issue if var.issue; mem }
        issues = issues.sort_by{|i| [i.issue_easy_sprint_relation.position || -1, -i.priority.position] }

        yield relation_type, relation_position, issues
      end
    end
  end

end
