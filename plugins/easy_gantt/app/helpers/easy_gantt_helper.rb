module EasyGanttHelper

  def easy_gantt_include_js(*javascripts, from_plugin: 'easy_gantt')
    plugin = (EasyGantt.easy_extensions? ? nil : from_plugin)

    result = ''
    javascripts.flatten!
    javascripts.compact!
    javascripts.each do |javascript|
      result << javascript_include_tag("#{from_plugin}/#{javascript}", plugin: plugin)+"\n"
    end
    result.html_safe
  end

  def easy_gantt_include_css(*stylesheets, media: 'screen', from_plugin: 'easy_gantt')
    plugin = (EasyGantt.easy_extensions? ? nil : from_plugin)

    result = ''
    stylesheets.flatten!
    stylesheets.compact!
    stylesheets.each do |stylesheet|
      result << stylesheet_link_tag("#{from_plugin}/#{stylesheet}", plugin: plugin, media: media)+"\n"
    end
    result.html_safe
  end

  def easy_gantt_js_button(text, options={})
    if text.is_a?(Symbol)
      lang_key = text
      text = l(lang_key, scope: [:easy_gantt, :button])
      options[:title] ||= l(lang_key, scope: [:easy_gantt, :title], default: text)
    end
    options[:class] = "gantt-menu-button #{options[:class]}"
    options[:class] << ' button' unless options.delete(:no_button)
    if (icon = options.delete(:icon))
      options[:class] << " icon #{icon}"
    end
    link_to(text, options[:url] || 'javascript:void(0)', options)
  end

  def easy_gantt_help_button(*args)
    options = args.extract_options!
    feature = args.shift
    text = args.shift

    options[:class] = "gantt-menu-help-button #{options[:class]}"
    options[:icon] ||= 'icon-help'
    options[:id] = 'button_' + feature.to_s + '_help'

    help_text = options[:help_text] || raw(l(options.delete(:easy_text) ? :easy_text : :text, scope: [:easy_gantt, :popup, feature]))

    easy_gantt_js_button(text || '&#8203;'.html_safe, options) + %Q(
    <div id="#{feature}_help_modal" style="display:none">
      <h3 class="title">#{raw l(:heading, scope: [:easy_gantt, :popup, feature]) }</h3>
      <p>#{help_text}</p>
     </div>
    ).html_safe
  end

  def api_render_versions(api, versions)
    return if versions.blank?

    api.array :versions do
      versions.each do |version|
        api.version do
          api.id version.id
          api.name version.name
          api.start_date version.effective_date
          api.project_id version.project_id
          api.project_name version.project&.name
          api.status version.status
          api.permissions do
            api.editable version.gantt_editable?
          end
        end
      end
    end

  end

  def api_render_columns(api, query)
    api.array :columns do
      query.columns.each do |c|
        api.column do
          api.name c.name
          api.title c.caption

          if c.is_a?(EasyQueryCustomFieldColumn) &&
             EasyGantt.dont_escape_custom_fields.include?(c.custom_field&.field_format)
              api.dont_escape true
          end
        end
      end
    end
  end

  def api_render_scheme(api, table)
    if table.is_a?(Symbol)
      if Object.const_defined?(table)
        table = Object.const_get(table)
      else
        return
      end
    end

    return unless table.column_names.include?('easy_color_scheme')

    col = table.arel_table[:easy_color_scheme]
    records = table.where(col.not_eq(nil).and(col.not_eq(''))).pluck(:id, :easy_color_scheme)

    api.array table.to_s do
      records.each do |id, scheme|
        api.entity do
          api.id id
          api.scheme scheme
        end
      end
    end
  end

  def api_render_holidays(api, startdt, enddt)
    wc = User.current.try(:current_working_time_calendar)
    return if wc.nil?

    api.array :holidays do
      startdt.upto(enddt) do |date|
        api.date date if wc.holiday?(date)
      end
    end

  end

  def api_render_issues(api, issues, with_columns: false)
    api.array :issues do
      issues.each do |issue|
        api.issue do
          api.id issue.id
          api.name issue.subject
          api.start_date issue.start_date
          api.due_date issue.due_date
          api.estimated_hours issue.estimated_hours
          api.done_ratio issue.done_ratio
          api.closed issue.closed?
          api.fixed_version_id issue.fixed_version_id
          api.overdue issue.overdue?
          api.parent_issue_id issue.parent_id
          api.project_id issue.project_id
          api.tracker_id issue.tracker_id
          api.priority_id issue.priority_id
          api.priority_position issue.priority ? issue.priority.position : 0
          api.status_id issue.status_id
          api.assigned_to_id issue.assigned_to_id

          if issue.project.module_enabled?(:time_tracking) && User.current.allowed_to?(:view_time_entries, issue.project)
            api.spent_hours issue.spent_hours
          end

          if EasySetting.value(:easy_gantt_show_task_soonest_start) && @project.nil?
            api.soonest_start issue.soonest_start
          end
          if EasySetting.value(:easy_gantt_show_task_latest_due) && @project.nil?
            api.latest_due issue.latest_due
          end

          api.is_planned !!issue.project.try(:is_planned)

          api.permissions do
            api.editable issue.gantt_editable?
          end

          if with_columns
            api.array :columns do
              @query.columns.each do |c|
                api.column do
                  api.name c.name
                  api.value gantt_format_column(issue, c, c.value(issue))
                end
              end
            end
          end

        end
      end
    end
  end

  def api_render_relations(api, relations)
    api.array :relations do
      relations.each do |rel|
        api.relation do
          api.id rel.id
          api.source_id rel.issue_from_id
          api.target_id rel.issue_to_id
          api.type rel.relation_type
          api.delay rel.delay.to_i
        end
      end
    end
  end

  def api_render_projects(api, projects, with_columns: false)
    api.array :projects do
      projects.each do |project|
        api.project do
          api.id project.id
          api.name project.name
          api.start_date project.gantt_start_date || Date.today
          api.due_date project.gantt_due_date || Date.today
          api.parent_id project.parent_id
          api.is_baseline project.try(:easy_baseline_for_id?)

          # Schema
          api.status_id project.status
          api.priority_id project.try(:easy_priority_id)

          api.permissions do
            api.editable project.gantt_editable?
          end

          if EasySetting.value(:easy_gantt_show_project_progress)
            api.done_ratio project.gantt_completed_percent
          end

          if @projects_issues_counts && @projects_issues_counts.has_key?(project.id)
            api.issues_count @projects_issues_counts[project.id]
          end

          if @all_project_tree && @all_project_tree.any?{|lft, rgt| lft > project.lft && rgt < project.rgt }
            api.has_subprojects true
          end

          if with_columns
            api.array :columns do
              @query.columns.each do |c|
                api.column do
                  api.name c.name
                  api.value gantt_format_column(project, c, c.value(project))
                end
              end
            end
          end

        end
      end
    end
  end

  # This method exist because
  #   1. EntityAttributeHelper is for complex html formating
  #   2. Redmine doest not have it
  # Gantt should show light and non-html values
  def gantt_format_column(entity, column, value)
    if column.is_a?(EasyQueryCustomFieldColumn) && (cv = entity.custom_value_for(column.custom_field))
      show_value(cv, false)
    elsif entity.is_a?(Project) && column.name == :status && respond_to?(:format_project_attribute)
      format_project_attribute(Project, column, value)
    elsif value.is_a?(Float) || value.is_a?(BigDecimal)
      locale = User.current.language.presence || ::I18n.locale
      number_with_precision(value, locale: locale).to_s
    elsif value.is_a?(Date)
      format_date(value)
    elsif value.is_a?(ActiveRecord::Associations::CollectionProxy)
      value.map{|v| v.to_s }.join(', ')
    else
      value.to_s
    end
  end

  def prepare_test_includes(tests)
    includes = []
    tests.each do |test_symbol|
      test_file = test_symbol.to_s
      if test_file.include?('/')
        split = test_file.split('/')
        plugin = split[0]
        test_file = split[1]
        includes << [test_file, plugin]
      end
    end
    includes
  end

end
