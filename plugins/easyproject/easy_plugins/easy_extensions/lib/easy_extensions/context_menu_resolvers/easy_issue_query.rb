module ContextMenuResolvers
  class EasyIssueQuery < ContextMenuResolver
    include IssuesHelper

    self.entity_klass = 'Issue'
    register_for 'EasyIssueQuery'

    def set_environment
      @issues               = entities
      @projects             = @issues.map(&:project)
      @issue_ids            = @issues.map(&:id).sort

      if @issues.size == 1
        @issue = @issues.first
        @project = @issue.project
      end

      @can = {
        edit:     @issues.all?(&:attributes_editable?),
        log_time: @project && User.current.allowed_to?(:log_time, @project),
        watch:    User.current.logged? && @issues.any? { |issue| issue.author_id != User.current.id && issue.assigned_to_id != User.current.id }
      }

      @options_by_custom_field = {}
      if @can[:edit]
        custom_fields = @issues.map(&:editable_custom_fields).reduce(:&).reject(&:multiple?)
        custom_fields.each do |field|
          values = field.possible_values_options(@projects)
          if values.present?
            @options_by_custom_field[field] = values
          end
        end
      end

      @can[:edit_basic_attrs] = @can[:edit] || (@project && User.current.allowed_to?(:add_issue_notes, @project))
      @safe_attributes = @issues.map(&:safe_attribute_names).reduce(:&)
    end

    def can_edit_attribute?(attr)
      @can[:edit] && @safe_attributes.include?(attr)
    end

    def item_allowed?(name)
      case name
      when 'edit'
        @can[:edit]
      when 'issue_timer'
        @can[:log_time] && @can[:edit] && @issue && EasyIssueTimer.active?(@issue.project)
      when 'status'
        can_edit_attribute?('status_id')
      when 'tracker'
        can_edit_attribute?('tracker_id')
      when 'priority'
        can_edit_attribute?('priority_id') && !@issues.any?(&:priority_derived?)
      when 'fixed_version'
        can_edit_attribute?('fixed_version_id')
      when 'assignee', 'assign_to_me'
        easy_distributed_tasks = @issues.detect { |i| i.tracker.easy_distributed_tasks? }.present?
        can_edit_attribute?('assigned_to_id') && !easy_distributed_tasks
      when 'author'
        can_edit_attribute?('author_id')
      when 'done_ratio', 'set_to_done'
        can_edit_attribute?('done_ratio') && Issue.use_field_for_done_ratio? && !@issues.any?(&:done_ratio_derived?)
      when 'project'
        can_edit_attribute?('project_id')
      when 'due_date_to_today'
        can_edit_attribute?('due_date') && !@issues.any? { |i| i.start_date && i.start_date > Date.today }
      when 'log_time'
        @issue && @can[:log_time]
      when 'copy'
        @issue && User.current.allowed_to?(:copy_issues, @projects) && Issue.allowed_target_projects.any?
      when 'delete'
        @issues.all?(&:deletable?)
      else
        false
      end
    end

    def registered_items
      {
        most_used: %w[assign_to_me set_to_done due_date_to_today],
        edit: %w[assignee status done_ratio tracker priority fixed_version project],
        action: %w[edit issue_timer log_time copy delete]
      }
    end

    def init_custom_field_items
      @options_by_custom_field.each do |field, options|
        possible_values = options.map do |value, key|
          build_possible_value(key || value, value)
        end

        add_custom_field_item field, url: default_url, possible_values: possible_values
      end
    end

    def init_edit_item
      if @issue && (@can[:edit] || @can[:edit_basic_attrs])
        url = edit_issue_path(@issue)
      elsif @can[:edit]
        url = bulk_edit_issues_path(ids: @issue_ids)
      else
        return
      end

      add_url_item name: l(:button_edit), url: url, icon: 'icon-edit'
    end

    def init_issue_timer_item
      timer  = @issue.easy_issue_timers.where(user_id: User.current.id).running.last
      attributes = Hash.new
      if timer && !timer.paused?
        attributes[:name]  = l(:button_easy_issue_timer_stop)
        attributes[:url]    = easy_issue_timer_stop_path(@issue, timer_id: timer)
        attributes[:icon]   = 'icon-checked-circle'
        attributes[:remote] = false
      else
        attributes[:name]  = l((timer.nil? ? :button_easy_issue_timer_play : :button_easy_issue_timer_resume))
        attributes[:url]    = easy_issue_timer_play_path(@issue, timer_id: timer)
        attributes[:icon]   = 'icon-play'
        attributes[:remote] = true
      end

      add_url_item attributes
    end

    def init_status_item
      statuses = @issues.map(&:new_statuses_allowed_to).reduce(:&)
      return unless statuses.present?

      if EasySetting.value(:close_subtask_after_parent)
        unselected_children_ids = []
        @issues.each do |issue|
          unselected_children_ids += issue.descendants.pluck(:id)
          unselected_children_ids -= [issue.id]
        end

        subtasks_to_close = unselected_children_ids.uniq.size
      end

      possible_values = statuses.map do |s|
        val = build_possible_value(s.id, s.name)
        val[:confirm] = subtasks_to_close && s.is_closed? && subtasks_to_close > 0 ? l(:text_issues_close_descendants_confirmation, count: subtasks_to_close) : nil
        val
      end

      add_list_item name: l(:field_status), url: default_url, url_prop: :status_id, possible_values: possible_values, icon: 'icon-issue-status'
    end

    def init_tracker_item
      trackers = @projects.map { |p| Issue.allowed_target_trackers(p) }.reduce(:&)
      return unless !trackers.nil? && trackers.size > 1

      possible_values = trackers.map do |t|
        build_possible_value(t.id, t.name)
      end

      add_list_item name: l(:field_tracker), url: default_url, url_prop: :tracker_id, possible_values: possible_values, icon: 'icon-tracker'
    end

    def init_priority_item
      priorities  = IssuePriority.active
      return unless priorities.present?

      possible_values =priorities.map do |p|
        build_possible_value(p.id, p.name)
      end

      add_list_item name: l(:field_priority), url: default_url, url_prop: :priority_id, possible_values: possible_values, icon: 'icon-list'
    end

    def init_fixed_version_item
      versions = @projects.map { |p| p.shared_versions.open }.reduce(:&).sort
      return unless versions.present?

      possible_values = versions.map do |v|
        build_possible_value(v.id, v.name)
      end

      possible_values.unshift(value: l(:label_none))

      add_list_item name: l(:field_fixed_version), url: default_url, url_prop: :fixed_version_id, possible_values: possible_values, icon: 'icon-stack'
    end

    def init_assignee_item
      source = 'assignable_principals_issue?'
      source << @issues.map(&:project_id).uniq.map do |project_id|
        "project_ids[]=#{project_id}"
      end.join('&')
      source << '&term='
      add_autocomplete_item name: l(:field_assigned_to), url: default_url, url_prop: :assigned_to_id, source: source, source_root: 'users', icon: 'icon-user'
    end

    def init_assign_to_me_item
      url = default_url(ids: @issue_ids, issue: { assigned_to_id: User.current.id })
      add_shortcut_item name: l(:field_easy_issue_timer_assign_to_me), url: url, icon: 'icon-user'
    end

    # TODO: autocomplete
    def init_author_item
      authors = @project.users.active.non_system_flag.sorted.to_a
      authors.push(@issue.author) if @issue && @issue.author && !authors.include?(@issue.author)
      return unless authors.present?

      possible_values = authors.map do |a|
        build_possible_value(a.id, a.name)
      end

      add_list_item name: l(:field_author), url: default_url, url_prop: :author_id, possible_values: possible_values, icon: 'icon-user'
    end

    def init_done_ratio_item
      possible_values = (0..100).step(10).map do |p|
        build_possible_value(p, "#{p}%")
      end

      add_list_item name: l(:field_done_ratio), url: default_url, url_prop: :done_ratio, possible_values: possible_values
    end

    def init_set_to_done_item
      add_shortcut_item name: l(:field_done_ratio_100), url: default_url(ids: @issue_ids, issue: { done_ratio: 100 }), icon: 'icon-checked'
    end

    def init_due_date_to_today_item
      add_shortcut_item name: l(:field_due_date_to_today), url: default_url(ids: @issue_ids, issue: { due_date: Date.today }), icon: 'icon-calendar'
    end

    def init_project_item
      add_autocomplete_item name: l(:label_project), url: issue_move_to_project_path, url_prop: :project_id, source: 'visible_projects?term=', source_root: 'projects', icon: 'icon-project'
    end

    # def init_watch_item
    #   watched = Watcher.any_watched?(entities, user)
    #   if (issues = entities.select { |object| object.is_a?(Issue) }).any?
    #     if issues.detect { |i| !User.current.allowed_to?(:add_issue_watchers, i.project) }
    #       return ''
    #     end
    #   end
    #
    #   css = [watcher_css(entities), watched ? 'icon icon-watcher watcher-fav' : 'icon icon-watcher watcher-fav-off'].join(' ')
    #   css << ' ' << options[:class].to_s if options[:class].present?
    #   text   = watched ? l(:button_unwatch) : l(:button_watch)
    #   url    = watch_path(object_type: entities.first.class.to_s.underscore, object_id: (entities.size == 1 ? entities.first.id : entities.map(&:id).sort)
    #   )
    #   method = watched ? 'delete' : 'post'
    #
    #   link_to text, url, :remote => true, :method => method, :class => css
    # end

    def init_log_time_item
      add_modal_item name: l(:button_log_time), modal_name: 'AntLogTime', icon: 'icon-time-add'
    end

    def init_copy_item
      add_url_item name: l(:button_copy), url: project_copy_issue_path(@project, @issue), icon: 'icon-copy'
    end

    def init_delete_item
      add_url_item name: l(:button_delete), url: issues_path(ids: @issue_ids), http_method: 'DELETE', confirm: issues_destroy_confirmation_message(@issues.to_a), icon: 'icon-del'
    end

    private

    def format_version_name(version)
      if version.project == @project
        version.name
      else
        "#{version.project.name} - #{version.name}"
      end
    end

    def default_url(params = {})
      bulk_update_issues_path(**params, format: :json)
    end

  end
end
