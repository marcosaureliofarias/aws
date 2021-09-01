class EasyIssueQuery < EasyQuery

  def self.entity_css_classes(issue, options = {})
    user  = options[:user] || User.current
    level = options[:level]
    issue.css_classes(user, level, options)
  end

  def self.permission_view_entities
    :view_issues
  end

  def query_after_initialize
    super
    self.export_formats[:atom]                     = { :url => { :key => User.current.rss_key } }
    self.export_formats[:ics]                      = { :caption => 'iCal', :url => { :protocol => 'webcal', :key => User.current.api_key, :only_path => false }, :title => l(:title_other_formats_links_ics_outlook) }
    self.display_project_column_if_project_missing = false
  end

  def additional_scope
    @additional_scope ||= project_scope
  end

  def filter_groups_ordering
    super + [
        EasyQuery.column_filter_group_name(nil),
        l(:label_filter_group_relations),
        l(:label_filter_group_easy_project_query),
        EasyQuery.column_filter_group_name(:project),
        EasyQuery.column_filter_group_name(:assigned_to),
        l(:label_filter_group_status_time),
        l(:label_filter_group_status_count)
    ]
  end

  def all_categories_values
    result = []
    IssueCategory.each_with_level(project.issue_categories) do |category, level|
      next if category.nil? || category.id.nil?

      name_prefix = (level > 0 ? '-' * level + ' ' : '')

      result << ["#{name_prefix}#{category}".html_safe, category.id.to_s]
    end
    result
  end

  def column_groups_ordering
    super + [
        EasyQuery.column_filter_group_name(nil),
        l(:label_filter_group_easy_time_entry_query),
        l(:label_filter_group_status_time),
        l(:label_filter_group_status_count)
    ]
  end

  def initialize_available_filters
    status_time_group  = l(:label_filter_group_status_time)
    status_count_group = l(:label_filter_group_status_count)
    project_id         = project.try(:id) unless Setting.cross_project_issue_relations?
    include_groups     = Setting.issue_group_assignment? || nil

    # Issues
    on_filter_group(default_group_label) do
      # Native
      add_available_filter 'subject', { type: :text, attr_reader: true, most_used: true }
      add_available_filter 'description', { type: :text, attr_reader: true, inline: false }
      add_available_filter 'start_date', { type: :date_period, time_column: false }
      add_available_filter 'due_date', { type: :date_period, time_column: false, most_used: true }
      add_available_filter 'created_on', { type: :date_period, time_column: true }
      add_available_filter 'updated_on', { type: :date_period, time_column: true }
      add_available_filter 'not_updated_on', { type: :date_period, time_column: true, label: :label_not_updated_on }
      add_available_filter 'last_updated_on', { type: :date_period, time_column: true, label: :label_updated_within }
      add_available_filter 'easy_status_updated_on', { type: :date_period, time_column: true }
      add_available_filter 'closed_on', { type: :date_period, time_column: true }
      add_available_filter 'open_duration_in_hours', { type: :float }
      add_available_filter 'done_ratio', { type: :integer, attr_reader: true, attr_writer: true }
      add_available_filter 'is_planned', { type: :boolean, includes: [:project] } unless project
      add_available_filter 'easy_external_id', { type: :string }

      if User.current.internal_client?
        add_available_filter 'easy_due_date_time', { type: :date_period, time_column: true, label: :field_hours_to_solve }
      end

      if User.current.allowed_to?(:view_estimated_hours, project, global: true)
        add_available_filter 'estimated_hours', { type: :float, attr_reader: true, attr_writer: true }
      end

      if EasySetting.value('allow_repeating_issues')
        add_available_filter 'easy_is_repeating', { type: :boolean }
      end

      if EasySetting.value(:enable_private_issues) && (User.current.allowed_to_globally?(:set_issues_private) || User.current.allowed_to_globally?(:set_own_issues_private))
        add_available_filter 'is_private', { type: :boolean }
      end

      # Issue
      add_available_filter 'issue_id', { type: :integer, label: :label_issue }
      add_available_filter 'child', { type: :list_autocomplete, source: 'issues_with_parents', source_root: 'entities', label: :label_subtask, klass: Issue }
      add_available_filter 'parent_id', { type: :list_autocomplete, source: 'issues_with_children', source_root: 'entities', source_options: { project_id: project_id }, label: :field_parent_issue, klass: Issue }
      add_available_filter 'root_id', { type: :list_autocomplete, source: 'root_issues', source_root: 'entities', source_options: { project_id: project_id }, label: :field_root_issue, klass: Issue }

      # Project
      unless project
        add_available_filter 'project_id', { type: :list_autocomplete, source: 'visible_projects', source_root: 'projects', data_type: :project, klass: Project }
        add_available_filter 'main_project', { type: :list_optional, values: proc { all_main_projects_values }, data_type: :project }
      end

      # Principal
      add_principal_autocomplete_filter 'assigned_to_id', { attr_reader: true, attr_writer: true, most_used: true, source_options: { include_groups: include_groups } }
      add_principal_autocomplete_filter 'author_id', { attr_reader: true, attr_writer: true }
      add_principal_autocomplete_filter 'watcher_id', { klass: User }
      add_principal_autocomplete_filter 'easy_last_updated_by_id'
      add_principal_autocomplete_filter 'easy_closed_by_id'
      add_principal_autocomplete_filter 'participant_id', { klass: User }
      add_principal_autocomplete_filter 'updated_by_who', { klass: User }
      add_principal_autocomplete_filter 'read_by', { klass: User }

      # Enumeration
      add_available_filter 'status_id', { type: :list_status, joins: [:status], attr_reader: true, attr_writer: true, values: proc { IssueStatus.sorted.map { |s| [s.name, s.id.to_s] } } }
      add_available_filter 'tracker_id', { type: :list, attr_reader: true, attr_writer: true, most_used: true, values: proc { trackers.map { |s| [s.name, s.id.to_s] } } }
      add_available_filter 'priority_id', { type: :list, most_used: true, values: proc { IssuePriority.active.sorted.map { |s| [s.name, s.id.to_s] } } }

      if project
        add_available_filter 'category_id', { type: :list_optional, values: proc { all_categories_values } }
      end

      # Other
      add_available_filter 'favorited', { type: :boolean }
      add_available_filter 'attachments', { type: :string, includes: [:attachments] }
      add_available_filter 'member_of_group', { type: :list_optional, values: proc { Group.givable.visible.sorted.collect { |g| [g.name, g.id.to_s] } } }
      if User.current.internal_client?
        add_available_filter 'assigned_to_role', { type: :list_optional, values: proc { Role.givable.sorted.collect { |r| [r.name, r.id.to_s] } } }
        add_available_filter 'author_by_role', { type: :list_optional, values: proc { Role.sorted.where.not(builtin: Role::BUILTIN_ANONYMOUS).collect { |r| [r.name, r.id.to_s] } } }
      end
      add_available_filter 'author_by_group', { type: :list_optional, values: proc { Group.givable.visible.sorted.collect { |g| [g.name, g.id.to_s] } } }
      add_available_filter 'tags', { type: :list_autocomplete, label: :label_easy_tags, source: 'tags', source_root: '' }

      if User.current.allowed_to?(:view_time_entries, project, global: true)
        add_available_filter 'sum_of_timeentries', { type: :float }
        add_available_filter 'spent_estimated_timeentries', { type: :float }
      end
    end

    # Versions
    on_filter_group(l(:label_filter_group_easy_version_query)) do
      if project
        add_available_filter 'fixed_version_id', { type: :list_version, includes: [:fixed_version], data_type: :version, values: proc {
          Version.values_for_select_with_project(project.shared_versions)
        } }
      else
        # Global filters for cross project issue list
        add_available_filter 'fixed_version_id', { type: :list_version, includes: [:fixed_version], data_type: :version, values: proc {
          Version.values_for_select_with_project(Version.visible.where(projects: { easy_is_easy_template: false }).joins(:project))
        } }
      end
      add_available_filter 'fixed_version.due_date', { type:        :date_period,
                                                       time_column: true,
                                                       name:        l(:label_attribute_of_fixed_version, name: l(:field_effective_date)),
                                                       includes:    [:fixed_version] }
      add_available_filter 'fixed_version.status', { type:     :list,
                                                     name:     l(:label_attribute_of_fixed_version, name: l(:field_status)),
                                                     values:   Version::VERSION_STATUSES.map { |s| [l("version_status_#{s}"), s] },
                                                     includes: [:fixed_version] }
    end

    # Relations
    on_filter_group(l(:label_filter_group_relations)) do
      IssueRelation::TYPES.each do |relation_type, options|
        add_available_filter relation_type, { type: :relation, order: 100, label: options[:name] }
      end
    end

    # Projects
    on_filter_group(l(:label_filter_group_easy_project_query)) do
      if project
        add_available_filter 'subproject_id',
                             { type:      :list_subprojects,
                               name:      "#{l(:field_subproject)} (#{l('easy_query.name.easy_project_query')})",
                               values:    proc { all_subprojects_values },
                               data_type: :project }
      else
        add_available_filter 'subprojects_of',
                             { type:      :list,
                               name:      "#{l(:field_subprojects_of)} (#{l('easy_query.name.easy_project_query')})",
                               values:    proc { all_projects_parents_values },
                               data_type: :project,
                               includes:  [:project] }
      end

      add_available_filter 'project_is_closed',
                           { type:     :boolean,
                             includes: [:project],
                             name:     "#{l(:field_is_project_closed)} (#{l('easy_query.name.easy_project_query')})" }
    end

    add_associations_filters EasyProjectQuery, only: ['is_public', 'name', 'easy_start_date', 'easy_due_date', 'created_on', 'author_id', 'easy_priority_id']

    # Statuses
    add_available_filter 'status_time_current', { type: :float, group: status_time_group }

    IssueStatus.sorted.limit(EasyReportIssueStatus::NO_OF_COLUMNS).each do |status|
      add_available_filter "status_time_#{status.id}",
                           { type:  :float,
                             group: status_time_group,
                             name:  l(:field_in_status, status: status.to_s),
                             joins: [:easy_report_issue_status] }

      add_available_filter "status_count_#{status.id}",
                           { type:  :integer,
                             group: status_count_group,
                             name:  l(:field_status_count, status: status.to_s),
                             joins: [:easy_report_issue_status] }
    end

    # Issue custom fields
    if project
      add_custom_fields_filters(project.all_issue_custom_fields)
    else
      add_custom_fields_filters(IssueCustomField)
    end

    # Others custom fields
    add_associations_custom_fields_filters :project, :author, :assigned_to, :fixed_version

    # Others
    Tracker.disabled_core_fields(trackers).each do |field|
      delete_available_filter(field)
    end
  end

  def initialize_available_columns
    group              = default_group_label
    time_entry_group   = l('label_filter_group_easy_time_entry_query')
    status_time_group  = l('label_filter_group_status_time')
    status_count_group = l('label_filter_group_status_count')

    @available_columns ||= []
    @available_columns.concat(
      [
        EasyQueryColumn.new(:project, most_used: true,
                            sortable: "#{Project.table_name}.name",
                            groupable: "#{Issue.table_name}.project_id", includes: [:project], group: group),
        EasyQueryColumn.new(:main_project, group: group),
        EasyQueryColumn.new(:parent,
                            sortable: ["#{Issue.table_name}.root_id", "#{Issue.table_name}.lft", 'parents_issues_sort.subject'],
                            default_order: 'desc', groupable: "#{Issue.table_name}.parent_id",
                            caption: :field_parent_issue, preload: [:parent], group: group,
                            attribute: 'parent_id', type: 'autocomplete', source_options: { source: 'parent_issues', source_root: 'parent_issues', params: { project_id: :project_id } }),
        EasyQueryColumn.new(:status,
                            sortable: "#{IssueStatus.table_name}.position",
                            groupable: "#{Issue.table_name}.status_id", includes: [:status], group: group,
                            attribute: 'status_id', type: 'autocomplete', source_options: { source: 'allowed_issue_statuses', params: { issue_id: :id } }),
        EasyQueryColumn.new(:tracker, icon: true, sortable: "joins_tracker.position", groupable: "#{Issue.table_name}.tracker_id",
                            preload: [:tracker], group: group, most_used: true,
                            attribute: 'tracker_id', type: 'autocomplete', source_options: { source: 'allowed_issue_trackers', params: { issue_id: :id } }),
        EasyQueryColumn.new(:priority, most_used: true,
                            sortable: "#{IssuePriority.table_name}.position", default_order: 'desc',
                            groupable: "#{Issue.table_name}.priority_id", includes: [:priority], group: group,
                            attribute: 'priority_id', type: 'autocomplete', source_options: { source: 'issue_priorities' }),
        EasyQueryColumn.new(:fixed_version,
                            sortable: lambda { Version.fields_for_order_statement('join_versions') },
                            groupable: true, preload: [:fixed_version], group: group,
                            attribute: 'fixed_version_id', type: 'autocomplete', source_options: { source: 'assignable_versions', params: { :issue_id => :id } }),
        EasyQueryColumn.new(:subject, :sortable => "#{Issue.table_name}.subject", :group => group, :most_used => true),
        EasyQueryDateColumn.new(:start_date, sortable: "#{Issue.table_name}.start_date", :group => group),
        EasyQueryDateColumn.new(:due_date, sortable: "#{Issue.table_name}.due_date", :group => group),
        EasyQueryDateColumn.new(:created_on, sortable: "#{Issue.table_name}.created_on", :default_order => 'desc', :group => group),
        EasyQueryDateColumn.new(:updated_on, :sortable => "#{Issue.table_name}.updated_on", :default_order => 'desc', :group => group),
        EasyQueryColumn.new(:easy_status_updated_on, :sortable => self.sql_time_diff("#{Issue.table_name}.easy_status_updated_on", "'#{Issue.connection.quoted_date(Time.now)}'"), :default_order => 'desc', :group => group),
        EasyQueryColumn.new(:open_duration_in_hours, :sortable => self.sql_time_diff("#{Issue.table_name}.created_on", "#{Issue.table_name}.closed_on"), :group => group),
        EasyQueryColumn.new(:easy_last_updated_by, :sortable => lambda { User.fields_for_order_statement('last_updator') }, :groupable => "#{Issue.table_name}.easy_last_updated_by_id", :preload => [:easy_last_updated_by => (Setting.gravatar_enabled? ? :email_addresses : :easy_avatar)], :group => group)
      ]
    )

    @available_columns << EasyQueryColumn.new(:done_ratio, sortable: "#{Issue.table_name}.done_ratio", :groupable => true, :group => group)
    @available_columns << EasyQueryColumn.new(:relations, :caption => :label_related_issues, :group => group)
    @available_columns << EasyQueryColumn.new(:description, :inline => false, :group => group)
    @available_columns << EasyQueryColumn.new(:attachments, :preload => [:attachments], :group => group)
    @available_columns << EasyQueryDateColumn.new(:closed_on, :sortable => "#{Issue.table_name}.closed_on", :group => group)
    @available_columns << EasyQueryColumn.new(:easy_closed_by, :groupable => true, :sortable => lambda { User.fields_for_order_statement('closed_by_users') }, :includes => [:easy_closed_by => :easy_avatar], :group => group)
    if User.current.internal_client?
      @available_columns << EasyQueryColumn.new(:easy_due_date_time_remaining, :sortable => "#{Issue.table_name}.easy_due_date_time", :caption => :field_hours_to_solve, :group => group)
    end

    if EasySetting.value(:enable_private_issues) && (User.current.allowed_to_globally?(:set_issues_private) || User.current.allowed_to_globally?(:set_own_issues_private))
      @available_columns << EasyQueryColumn.new(:is_private, :sortable => "#{Issue.table_name}.is_private", :group => group)
    end
    unless EasyExtensions::EasyProjectSettings.disabled_features[:others].include?('issue_categories')
      @available_columns << EasyQueryColumn.new(:category, :sortable => "#{IssueCategory.table_name}.name", :groupable => "#{IssueCategory.table_name}.id", :includes => [:category], :group => group, :attribute => 'category_id')
      @available_columns << EasyQueryColumn.new(:parent_category, :sortable => 'join_category_parent.name', :groupable => 'join_category_parent.id', :joins => joins_for_parent_category_field, :group => group)
      @available_columns << EasyQueryColumn.new(:root_category, :group => group)
    end
    @available_columns << EasyQueryColumn.new(:id, :sortable => "#{Issue.table_name}.id", :group => group) if EasySetting.value('show_issue_id', project)

    @available_columns << EasyQueryColumn.new(:parent_project, :sortable => 'join_parent.name', :groupable => 'join_parent.id', :group => group)

    @available_columns << EasyQueryColumn.new(:assigned_to, :most_used => true,
                                              sortable: lambda { User.fields_for_order_statement('issue_assigned_to') },
                                              :groupable => "#{Issue.table_name}.assigned_to_id", group: group,
                                              preload: [{:project => :enabled_modules}, {:assigned_to => :easy_avatar}],
                                              :attribute => 'assigned_to_id', type: 'autocomplete',
                                              :source_options => { :source => 'assignable_principals_issue', source_root: 'users', :params => { :issue_id => :id } })
    @available_columns << EasyQueryColumn.new(:author, groupable: "#{Issue.table_name}.author_id",
                                              :sortable => lambda { User.fields_for_order_statement('authors') },
                                              :preload => [:author => :easy_avatar], :group => group, :most_used => true, type: 'autocomplete',
                                              :attribute => 'author_id', :source_options => { :source => 'issue_author_values', :params => { :issue_id => :id } })
    @available_columns << EasyQueryColumn.new(:watchers, :caption => :field_watcher, :preload => [:watchers => :user], :group => group)
    @available_columns << EasyQueryColumn.new(:tags, :preload => [:tags], :caption => :label_easy_tags, :group => group)
    @available_columns << EasyQueryColumn.new(:easy_external_id, :caption => :field_easy_external, :group => group)

    if !project || project.fixed_activity?
      @available_columns << EasyQueryColumn.new(:activity, :sortable => 'tactivity.position', :groupable => "#{Issue.table_name}.activity_id", :preload => [:activity], :group => group, :attribute => 'activity_id')
    end

    if User.current.allowed_to?(:view_estimated_hours, project, { :global => true })
      @available_columns << EasyQueryColumn.new(:estimated_hours, :sortable => "#{Issue.table_name}.estimated_hours", :sumable => :bottom, :group => time_entry_group)
      @available_columns << EasyQueryColumn.new(:total_estimated_hours,
                                                :sortable      => "COALESCE((SELECT SUM(estimated_hours) FROM #{Issue.table_name} subtasks" +
                                                    " WHERE subtasks.root_id = #{Issue.table_name}.root_id AND subtasks.lft >= #{Issue.table_name}.lft AND subtasks.rgt <= #{Issue.table_name}.rgt), 0)",
                                                :default_order => 'desc', :caption => :field_sum_estimated_hours, :group => time_entry_group)
    end
    if project ? User.current.allowed_to?(:view_time_entries, project) : User.current.allowed_to_globally?(:view_time_entries, {})
      @available_columns << EasyQueryColumn.new(:spent_hours, :caption => :field_time_entry, :sumable => :bottom, :sumable_sql => "COALESCE((SELECT SUM(t.hours) FROM #{TimeEntry.table_name} t WHERE t.issue_id = #{Issue.table_name}.id), 0)", :group => time_entry_group)
      @available_columns << EasyQueryColumn.new(:total_spent_hours,
                                                :sortable      => "COALESCE((SELECT SUM(hours) FROM #{TimeEntry.table_name} JOIN #{Issue.table_name} subtasks ON subtasks.id = #{TimeEntry.table_name}.issue_id" +
                                                    " WHERE subtasks.root_id = #{Issue.table_name}.root_id AND subtasks.lft >= #{Issue.table_name}.lft AND subtasks.rgt <= #{Issue.table_name}.rgt), 0)",
                                                :default_order => 'desc',
                                                :caption       => :label_total_spent_time, :group => time_entry_group
      )

      @available_columns << EasyQueryColumn.new(:remaining_timeentries, :sumable => :bottom, :sumable_sql => "COALESCE(#{Issue.table_name}.estimated_hours, 0) - COALESCE((SELECT SUM(t.hours) FROM #{TimeEntry.table_name} t WHERE t.issue_id = #{Issue.table_name}.id), 0)", :group => time_entry_group)
      @available_columns << EasyQueryColumn.new(:total_remaining_timeentries, :numeric => true, :group => time_entry_group)
      @available_columns << EasyQueryColumn.new(:spent_estimated_timeentries, :numeric => true, :group => time_entry_group)
      @available_columns << EasyQueryColumn.new(:total_spent_estimated_timeentries, :numeric => true, :group => time_entry_group)
    end

    # Repeating options
    @available_columns << EasyQueryColumn.new(:easy_next_start, :sortable => "#{Issue.table_name}.easy_next_start", :group => group)

    @available_columns << EasyQueryColumn.new(:status_time_current, :sortable => "#{Issue.table_name}.easy_status_updated_on", :default_order => 'desc', :numeric => true, :group => status_time_group)
    statuses = IssueStatus.sorted.limit(EasyReportIssueStatus::NO_OF_COLUMNS)
    statuses.each do |status|
      @available_columns << EasyQueryParameterizedColumn.new(:"status_time_#{status.id}", :arguments => status.id, :method => 'get_status_time',
                                                             :title                                  => l(:field_in_status, :status => status.to_s), :preload => [:easy_report_issue_status], :numeric => true, :group => status_time_group)
    end

    statuses.each do |status|
      @available_columns << EasyQueryParameterizedColumn.new(:"status_count_#{status.id}", :arguments => status.id, :method => 'get_status_count',
                                                             :title                                   => l(:field_status_count, :status => status.to_s), :preload => [:easy_report_issue_status], :numeric => true, :group => status_count_group)
    end

    @available_columns.concat(IssueCustomField.sorted.visible.for_project(project).collect { |cf| EasyQueryCustomFieldColumn.new(cf) })

  end

  def available_columns
    unless @available_columns_added
      initialize_available_columns

      disabled_fields = Tracker.disabled_core_fields(trackers).map { |field| field.sub(/_id$/, '') }
      @available_columns.reject! { |column| disabled_fields.include?(column.name.to_s) }

      @available_columns_added = true
    end

    @available_columns
  end

  def joins_for_easy_last_updated_by_field
    main_entity = entity.arel_table
    user        = User.arel_table.alias('last_updator')
    join_users  = main_entity.create_on(main_entity[:easy_last_updated_by_id].eq(user[:id]))

    main_entity.create_join(user, join_users, Arel::Nodes::OuterJoin).to_sql
  end

  def project=(project)
    @available_filters = nil # reset cached filters on project change
    super
  end

  def gantt_columns
    columns.select { |c| ![:subject, :description].include?(c.name) }
  end

  def searchable_columns
    ["#{Issue.table_name}.subject"]
  end

  def sortable_columns
    c            = super
    c['root_id'] = "#{Issue.table_name}.root_id"
    c['lft']     = "#{Issue.table_name}.lft"
    c
  end

  def entity
    Issue
  end

  def calendar_options
    { start_date_filter: 'start_date', end_date_filter: 'due_date' }
  end

  def default_find_joins
    [:priority, :project]
  end

  def default_find_preload
    #priority and status for css classes
    [:tracker, :current_user_read_records, :priority, :status]
  end

  def default_groups_preload
    [:project]
  end

  def columns_with_me
    super + ['participant_id', 'updated_by_who', 'read_by', 'easy_closed_by_id', 'easy_last_updated_by_id']
  end

  def entity_context_menu_path(options = {})
    issues_context_menu_path(options)
  end

  def self.chart_support?
    true
  end

  def calendar_support?
    true
  end

  def trackers
    @trackers ||= (project.nil? ? Tracker.all : project.rolled_up_trackers).visible.sorted
  end

  def preloads_for_entities(issues)
    if has_custom_field_column?
      Issue.load_available_custom_fields_cache(issues.collect(&:project_id).uniq)
    end
    if has_column?(:spent_hours)
      Issue.load_visible_spent_hours(issues)
    end
    if has_column?(:total_spent_hours)
      Issue.load_visible_total_spent_hours(issues)
    end
    if has_column?(:relations)
      Issue.load_visible_relations(issues)
    end
    if has_column?(:total_estimated_hours)
      Issue.load_visible_total_estimated_hours(issues)
    end
    Issue.load_workflow_rules(issues)
  end

  def entities(options = {})
    issues = super(options)
    preloads_for_entities(issues)
    issues
  end

  def entities_for_group(group, options = {})
    issues = super
    preloads_for_entities(issues)
    issues
  end

  def issue_count_by_group(options = {})
    entity_count_by_group(options)
  end

  def issue_sum_by_group(column, options = {})
    entity_sum_by_group(column, options)
  end

  # Returns the journals
  # Valid options are :order, :offset, :limit
  def journals(options = {})
    Journal.visible.
        joins(:issue => [:project, :status]).
        where(journalized_type: 'Issue').
        where(self.statement).
        order(options[:order]).
        limit(options[:limit]).
        offset(options[:offset]).
        preload(:details, :user, { :issue => [:project, :author, :tracker, :status] }).
        to_a
  rescue ::ActiveRecord::StatementInvalid => e
    raise StatementInvalid.new(e.message)
  end

  # Returns the versions
  # Valid options are :conditions
  def versions(options = {})
    Version.visible.
        merge(self.additional_scope).
        where(options[:conditions]).
        includes(:project).
        references(:project).
        to_a
  rescue ::ActiveRecord::StatementInvalid => e
    raise StatementInvalid.new(e.message)
  end

  def issues_with_versions(options = {})
    result = prepare_export_result(options)
    return [] if result.keys.empty?

    all_issues = result.values.collect { |v| v[:entities] }.flatten
    subtasks   = []
    result.each do |key, data|
      data[:entities].delete_if { |i| i.parent && all_issues.include?(i.parent) && subtasks << i }
    end

    if project && (!grouped? || group_by == 'project')

      if EasySetting.value('gantt_show_all_versions', project)
        versions = project.shared_versions.reorder("#{Version.table_name}.effective_date ASC, #{Version.table_name}.name DESC").to_a
      else
        versions    = []
        version_ids = []
        result.each do |key, issues|
          version_ids |= issues[:entities].collect(&:fixed_version_id).compact
        end
        if version_ids.any?
          versions = Version
          versions = versions.preload(:project) if grouped?
          versions = versions.where(:id => version_ids).reorder("#{Version.table_name}.effective_date ASC, #{Version.table_name}.name DESC")
          #.delete_if{|v| v.effective_date.nil?}.sort{|a, b| b.effective_date <=> a.effective_date}
        end
      end
      result.each do |key, issues|
        if grouped? #grouped by project solved only!
          group_versions = versions.select { |v| v.project == key }
        else
          group_versions = versions
        end
        versions -= group_versions

        ii                = issues[:entities].group_by(&:fixed_version_id) # .inject([]){|mem,var| mem += var.last; mem << var.first; mem}
        issues[:entities] = Array(ii[nil])
        issues[:entities].concat(group_versions.inject([]) { |mem, var| mem += Array(ii[var.id]); mem << var; mem })
      end

      result[result.keys.last][:entities].concat versions.reverse
      if EasySetting.value('gantt_versions_above', project)
        result.each do |key, issues|
          reordered      = []
          issues_to_push = []
          issues[:entities].each do |entity|
            if entity.is_a?(Issue)
              issues_to_push << entity
            elsif entity.is_a?(Version) || entity.nil?
              reordered << entity
              reordered.concat issues_to_push
              issues_to_push = []
            end
          end
          reordered.concat issues_to_push
          issues[:entities] = reordered
        end
      end
    end

    subtasks = subtasks.group_by &:easy_level

    subtasks.keys.sort.each do |level|
      subtasks[level].reverse_each do |subtask|
        v_hash = result.values.detect { |v| v[:entities].include?(subtask.parent) }
        v_hash[:entities].insert(v_hash[:entities].index(subtask.parent) + 1, subtask) if v_hash
      end
    end

    if grouped? && group_by == 'project'
      result.to_a.sort { |a, b| a[0].lft <=> b[0].lft }
    else
      result
    end
  end

  def extended_period_options
    {
        :extended_options       => [:to_today, :is_null, :is_not_null, :from_tomorrow],
        :option_limit           => {
            :after_due_date => ['due_date'],
            :next_week      => ['due_date', 'start_date'],
            :tomorrow       => ['due_date', 'start_date'],
            :next_7_days    => ['due_date', 'start_date'],
            :next_14_days   => ['due_date', 'start_date'],
            :next_15_days   => ['due_date', 'start_date'],
            :next_30_days   => ['due_date', 'start_date'],
            :next_90_days   => ['due_date', 'start_date'],
            :next_month     => ['due_date', 'start_date'],
            :next_year      => ['due_date', 'start_date']
        },
        :field_disabled_options => {
            'not_updated_on' => [:is_null, :is_not_null]
        }
    }
  end

  def additional_group_attributes(group, attributes, options = {})
    attributes[:percent] = (attributes[:count] / options[:global_count].to_f * 100).round(2) if attributes[:count] && options[:global_count] > 0
    attributes[:percent] ||= 0
  end

  def statement_skip_fields
    ['subproject_id', 'subprojects_of', 'is_planned']
  end

  def project_scope
    scope = Project.all

    if force_current_project_filter && self.project
      scope = scope.where(id: self.project.id)
    elsif self.project && !self.project.descendants.empty?
      if self.has_filter?('subproject_id')
        case self.operator_for('subproject_id')
        when '='
          # include the selected subprojects
          ids   = [self.project.id] + values_for('subproject_id').select(&:present?).map(&:to_i)
          scope = scope.where(id: ids)
        when '!'
          # exclude the selected subprojects
          ids   = self.project.self_and_descendants.pluck(:id) - values_for('subproject_id').select(&:present?).map(&:to_i)
          scope = scope.where(id: ids)
        when 'only='
          #only selected subprojects
          ids   = values_for('subproject_id').select(&:present?).each(&:to_i)
          scope = scope.where(id: ids)
        when '!*'
          # main project only
          scope = scope.where(id: self.project.id)
        else
          # all subprojects
          scope = scope.merge(self.project.self_and_descendants.reorder(nil))
        end
      elsif Setting.display_subprojects_issues?
        scope = scope.merge(self.project.self_and_descendants.reorder(nil))
      else
        scope = scope.where(id: self.project.id)
      end
    elsif self.project
      scope = scope.where(id: self.project.id)
    else
      scope = scope.non_templates

      if has_filter?('subprojects_of')
        values = values_for('subprojects_of').select(&:present?).map(&:to_i)
        if values.any? && (projects_tree = Project.where(id: values).pluck(:lft, :rgt)).any?
          projects_tree.map! do |lft, rgt|
            "(#{Project.table_name}.lft >= #{lft} AND #{Project.table_name}.rgt <= #{rgt})"
          end
          projects_tree = projects_tree.join(' OR ')

          case operator_for('subprojects_of')
          when '='
            scope = scope.where(projects_tree)
          else
            scope = scope.where.not(projects_tree)
          end
        end
      end

      if self.has_filter?('is_planned') && self.values_for('is_planned').size == 1
        planned_val = value_for('is_planned').to_s.to_boolean
        planned_val = !planned_val if operator_for('is_planned') == '!='
        arel_status = Project.arel_table[:status]
        scope       = scope.where(planned_val ? arel_status.eq(Project::STATUS_PLANNED) : arel_status.not_eq(Project::STATUS_PLANNED))
      end
    end
    scope
  end

  def add_additional_order_statement_joins(order_options)
    joins = []
    if order_options
      if order_options.include?('authors')
        joins << "LEFT OUTER JOIN #{User.table_name} authors ON authors.id = #{Issue.table_name}.author_id"
      end
      if order_options.include?('issue_assigned_to')
        joins << "LEFT OUTER JOIN #{User.table_name} issue_assigned_to ON issue_assigned_to.id = #{Issue.table_name}.assigned_to_id"
      end
      if order_options.include?('closed_by_users')
        joins << "LEFT OUTER JOIN #{User.table_name} closed_by_users ON closed_by_users.id = #{Issue.table_name}.easy_closed_by_id"
      end
      if order_options.include?('main_project') && col = available_columns.detect { |col| col.name == :main_project }
        joins << col.joins
      end
      if order_options.include?('join_category_parent') && col = available_columns.detect { |col| (col.name == :parent_category) }
        joins << col.joins
      end
      if order_options.include?('join_category_root') && col = available_columns.detect { |col| (col.name == :root_category) }
        joins << col.joins
      end
      if order_options.include?('join_versions')
        joins << "LEFT OUTER JOIN #{Version.table_name} join_versions ON join_versions.id = #{Issue.table_name}.fixed_version_id"
      end
      if order_options.include?('tactivity') && available_columns.detect { |col| (col.name == :activity) }
        joins << "LEFT OUTER JOIN #{TimeEntryActivity.table_name} tactivity ON tactivity.id = #{Issue.table_name}.activity_id"
      end
      if order_options.include?('last_updator') && available_columns.detect { |col| (col.name == :easy_last_updated_by) }
        joins << joins_for_easy_last_updated_by_field
      end
      if order_options.include?('parents_issues_sort')
        joins << "LEFT OUTER JOIN #{Issue.table_name} parents_issues_sort ON #{Issue.table_name}.parent_id = parents_issues_sort.id"
      end
      if order_options.include?('joins_tracker')
        joins << "INNER JOIN #{Tracker.table_name} joins_tracker ON joins_tracker.id = #{Issue.table_name}.tracker_id"
      end
      if order_options.include?('join_parent')
        joins << joins_for_parent_project_field
      end
    end
    return joins
  end

  def sql_for_parent_project_id_field(field, operator, value)
    '(' << sql_for_field(field, operator, value, Project.table_name, 'parent_id') + ')'
  end

  def sql_for_watcher_id_field(field, operator, value)
    db_table = Watcher.table_name
    db_field = 'user_id'
    is_not = operator.include?('!')
    sql = +"#{is_not ? 'NOT ' : ''}EXISTS (SELECT 1 FROM #{db_table} WHERE #{db_table}.watchable_type='Issue' AND "
    sql << "#{db_table}.watchable_id = #{entity_table_name}.id"
    sql << " AND #{sql_for_field(field, '=', value, db_table, db_field)}" unless operator.include?('*')
    sql << ')'
    sql
  end

  def sql_for_attachments_field(field, operator, value)
    "(#{sql_for_field(field, operator, value, Attachment.table_name, 'filename')})"
  end

  def sql_for_fixed_version_status_field(field, operator, value)
    where       = sql_for_field(field, operator, value, Version.table_name, 'status')
    version_ids = versions(:conditions => [where]).map(&:id)
    nl          = operator == '!' ? "#{Issue.table_name}.fixed_version_id IS NULL OR" : ''
    "(#{nl} #{sql_for_field("fixed_version_id", '=', version_ids, Issue.table_name, "fixed_version_id")})"
  end

  def sql_for_fixed_version_due_date_field(field, operator, value)
    if (value.try(:[], 'period') == 'is_null')
      "#{Issue.table_name}.fixed_version_id IS NULL"
    else
      where       = sql_for_field(field, operator, value, Version.table_name, 'effective_date')
      version_ids = versions(:conditions => [where]).map(&:id)
      "(#{sql_for_field("fixed_version_id", '=', version_ids, Issue.table_name, "fixed_version_id")})"
    end
  end

  def sql_for_member_of_group_field(field, operator, value)
    if operator == '*' # Any group
      groups   = Group.givable
      operator = '=' # Override the operator since we want to find by assigned_to
    elsif operator == '!*'
      groups   = Group.givable
      operator = '!' # Override the operator since we want to find by assigned_to
    else
      groups = Group.where(:id => value)
    end

    members_of_groups = groups.joins(:users).distinct.pluck('users_users.id')

    sql = '(' + sql_for_field('assigned_to_id', operator, members_of_groups, Issue.table_name, 'assigned_to_id', false) + ')'
    sql
  end

  def sql_for_assigned_to_role_field(field, operator, value)
    roles    = Role.givable
    inverse  = true if ['!', '!*'].include?(operator)
    roles    = roles.where(:id => value) unless ['*', '!*'].include?(operator)
    role_ids = roles.pluck(:id)

    sql = "#{inverse ? 'NOT ' : ''}EXISTS(SELECT 1 "
    sql << "FROM #{Member.table_name} INNER JOIN member_roles ON member_roles.member_id = members.id "
    sql << "WHERE (#{sql_for_field('role_id', '=', role_ids, 'member_roles', 'role_id', false)}) "
    sql << "AND #{Member.table_name}.user_id = #{Issue.table_name}.assigned_to_id "
    sql << "AND #{Member.table_name}.project_id = #{Issue.table_name}.project_id) "
    sql
  end

  def sql_for_spent_estimated_timeentries_field(field, operator, value)
    db_table = ''
    db_field = "(CASE WHEN (#{Issue.table_name}.estimated_hours > 0) THEN (COALESCE((SELECT SUM(t.hours) FROM #{TimeEntry.table_name} t WHERE t.issue_id = #{Issue.table_name}.id), 0) / #{Issue.table_name}.estimated_hours) * 100 ELSE 0 END)"
    sql      = sql_for_field('spent_estimated_timeentries', operator, value, db_table, db_field)
    sql
  end

  def sql_for_sum_of_timeentries_field(field, operator, value)
    db_table = ''
    db_field = "(SELECT SUM(t.hours) FROM #{TimeEntry.table_name} t WHERE t.issue_id = #{Issue.table_name}.id)"
    db_field = "COALESCE(#{db_field}, 0)" unless operator.include?('*')
    sql_for_field(field, operator, value, db_table, db_field)
  end

  def sql_for_estimated_hours_field(field, operator, value)
    db_table = ''
    db_field = "COALESCE(#{Issue.table_name}.estimated_hours, 0)"
    sql      = sql_for_field(field, operator, value, db_table, db_field)
    sql
  end

  def sql_for_is_private_field(field, operator, value)
    op = (operator == "=" ? 'IN' : 'NOT IN')
    va = value.map { |v| v == '0' ? self.class.connection.quoted_false : self.class.connection.quoted_true }.uniq.join(',')
    "#{Issue.table_name}.is_private #{op} (#{va})"
  end

  def only_favorited?
    filters.include?('favorited')
  end

  def sql_for_updated_by_who_field(field, operator, value)
    all                     = true if operator.include?('*')
    statements_for_journals = []
    statements_for_journals << "#{Journal.table_name}.journalized_id = #{Issue.table_name}.id AND #{Journal.table_name}.journalized_type = 'Issue'"
    statements_for_journals << sql_for_field(field, all ? '*' : '=', value, Journal.table_name, 'user_id', false)

    filter_by_who = "#{'NOT ' if operator.start_with? '!'}EXISTS ( SELECT 1 FROM #{Journal.table_name}"
    filter_by_who << ' WHERE ' << statements_for_journals.reject { |sql| sql.blank? }.join(' AND ') << ')'

    filter_by_who
  end

  def sql_for_last_updated_on_field(field, operator, value)
    statements_for_journals = []

    statements_for_journals << "#{Journal.table_name}.journalized_id = #{Issue.table_name}.id AND #{Journal.table_name}.journalized_type = 'Issue'"
    statements_for_journals << sql_for_field(field, operator, value, Journal.table_name, 'created_on', false)

    filter_by_updated_on = "EXISTS ( SELECT 1 FROM #{Journal.table_name}"
    filter_by_updated_on << ' WHERE ' << statements_for_journals.reject { |sql| sql.blank? }.join(' AND ') << ')'

    filter_by_updated_on
  end

  def sql_for_not_updated_on_field(field, operator, value)
    db_field = 'updated_on'
    db_table = self.entity.table_name

    if operator =~ /date_period_([12])/
      if $1 == '1' && value[:period].to_sym == :all
        "#{Issue.quoted_table_name}.#{db_field} = #{Issue.quoted_table_name}.created_on"
      else
        period_dates = self.get_date_range($1, value[:period], value[:from], value[:to], value[:period_days])
        self.reversed_date_clause(db_table, db_field, (period_dates[:from].nil? ? nil : period_dates[:from].beginning_of_day), (period_dates[:to].nil? ? nil : period_dates[:to].end_of_day), field: field)
      end
    else
      nil # not supported
    end
  end

  def sql_for_updated_on_field(field, operator, value)
    db_field = 'updated_on'
    db_table = self.entity.table_name

    if operator =~ /date_period_([12])/
      if $1 == '1' && value[:period].to_sym == :all
        nil
      else
        period_dates = self.get_date_range($1, value[:period], value[:from], value[:to], value[:period_days])
        self.date_clause(db_table, db_field, (period_dates[:from].nil? ? nil : period_dates[:from].beginning_of_day), (period_dates[:to].nil? ? nil : period_dates[:to].end_of_day), field: field)
      end
    else
      sql_for_field(field, operator, value, db_table, db_field)
    end
  end

  def get_custom_sql_for_field(field, operator, value)
    f = field.to_s
    if /status_time_\d+/.match?(f)
      sql_for_status_time(field, operator, value)
    elsif /status_count_\d+/.match?(f)
      sql_for_status_count(field, operator, value)
    else
      super(field, operator, value)
    end
  end

  def sql_for_participant_id_field(field, operator, value)
    filters_clauses = []
    ['assigned_to_id', 'author_id', 'watcher_id'].each do |part_field|
      v = value
      if part_field == 'assigned_to_id'
        if v.is_a?(Array)
          additional = []
          v.each do |user_id|
            user       = User.find_by(:id => user_id)
            additional |= user.group_ids.map(&:to_s) if user
          end
          v.concat(additional)
        end
      end

      custom_sql = self.get_custom_sql_for_field(part_field, operator, v)
      unless custom_sql.blank?
        filters_clauses << custom_sql
        next
      end

      if respond_to?("sql_for_#{part_field}_field")
        # specific statement
        filters_clauses << send("sql_for_#{part_field}_field", part_field, operator, v)
      else
        db_table               = self.entity.table_name
        db_field               = part_field
        returned_sql_for_field = self.sql_for_field(part_field, operator, v, db_table, db_field)
        filters_clauses << ('(' + returned_sql_for_field + ')') unless returned_sql_for_field.blank?
      end
    end
    '(' << filters_clauses.join(' OR ') << ')'
  end

  def sql_for_relations(field, operator, value, options = {})
    relation_options = IssueRelation::TYPES[field]
    return relation_options unless relation_options

    relation_type                   = field
    join_column, target_join_column = 'issue_from_id', 'issue_to_id'
    if relation_options[:reverse] || options[:reverse]
      relation_type                   = relation_options[:reverse] || relation_type
      join_column, target_join_column = target_join_column, join_column
    end

    sql = case operator
          when '*', '!*'
            op = (operator == '*' ? 'IN' : 'NOT IN')
            "#{Issue.table_name}.id #{op} (SELECT DISTINCT #{IssueRelation.table_name}.#{join_column} FROM #{IssueRelation.table_name} WHERE #{IssueRelation.table_name}.relation_type = '#{self.class.connection.quote_string(relation_type)}')"
          when '=', '!'
            op = (operator == '=' ? 'IN' : 'NOT IN')
            "#{Issue.table_name}.id #{op} (SELECT DISTINCT #{IssueRelation.table_name}.#{join_column} FROM #{IssueRelation.table_name} WHERE #{IssueRelation.table_name}.relation_type = '#{self.class.connection.quote_string(relation_type)}' AND #{IssueRelation.table_name}.#{target_join_column} = #{value.last.to_i})"
          when '=p', '=!p', '!p'
            op   = (operator == '!p' ? 'NOT IN' : 'IN')
            comp = (operator == '=!p' ? '<>' : '=')
            "#{Issue.table_name}.id #{op} (SELECT DISTINCT #{IssueRelation.table_name}.#{join_column} FROM #{IssueRelation.table_name}, #{Issue.table_name} relissues WHERE #{IssueRelation.table_name}.relation_type = '#{self.class.connection.quote_string(relation_type)}' AND #{IssueRelation.table_name}.#{target_join_column} = relissues.id AND relissues.project_id #{comp} #{value.last.to_i})"
          when '*o', '!o'
            op = (operator == '!o' ? 'NOT IN' : 'IN')
            "#{Issue.table_name}.id #{op} (SELECT DISTINCT #{IssueRelation.table_name}.#{join_column} FROM #{IssueRelation.table_name}, #{Issue.table_name} relissues WHERE #{IssueRelation.table_name}.relation_type = '#{self.class.connection.quote_string(relation_type)}' AND #{IssueRelation.table_name}.#{target_join_column} = relissues.id AND relissues.status_id IN (SELECT id FROM #{IssueStatus.table_name} WHERE is_closed=#{self.class.connection.quoted_false}))"
          end

    if relation_options[:sym] == field && !options[:reverse]
      sqls = [sql, sql_for_relations(field, operator, value, :reverse => true)]
      sql  = sqls.join(["!", "!*", "!p", '!o'].include?(operator) ? " AND " : " OR ")
    end
    "(#{sql})"
  end

  def sql_for_read_by_field(field, operator, value)
    tbl       = EasyUserReadEntity.table_name
    user_cond = EasyUserReadEntity.arel_table[:user_id].in(value).to_sql
    "#{operator == '=' ? '' : 'NOT '}EXISTS (SELECT 1 FROM #{tbl} WHERE #{user_cond} AND #{tbl}.entity_type = '#{self.entity.name}' AND #{tbl}.entity_id = #{entity_table_name}.id)"
  end

  IssueRelation::TYPES.each_key do |relation_type|
    alias_method "sql_for_#{relation_type}_field".to_sym, :sql_for_relations
  end

  def sql_for_status_time(field, operator, value)
    if field.match /(\d+)/
      minutes = value.map { |v| (v.to_f * 1.minute).round.to_s }

      status_id = $1.to_i
      idx = EasyReportIssueStatus.get_idx(status_id)
      if idx && status_id > 0 && idx <= EasyReportIssueStatus::NO_OF_COLUMNS
        sql = sql_for_field(field, operator, minutes, EasyReportIssueStatus.table_name, "status_time_#{idx}")
      end
    end
    sql ||= '(1=0)'
  end

  def sql_for_status_count(field, operator, value)
    if field.match /(\d+)/
      status_id = $1.to_i
      idx = EasyReportIssueStatus.get_idx(status_id)
      if idx && status_id > 0 && idx <= EasyReportIssueStatus::NO_OF_COLUMNS
        sql = sql_for_field(field, operator, value, EasyReportIssueStatus.table_name, "status_count_#{idx}")
      end
    end
    sql ||= '(1=0)'
  end

  def sql_for_open_duration_in_hours_field(field, operator, value)
    sql_for_field(field, operator, value, nil, self.sql_time_diff("#{Issue.table_name}.created_on", "#{Issue.table_name}.closed_on"))
  end

  def sql_for_status_time_current_field(field, operator, value)
    sql_for_field(field, operator, value, nil, self.sql_time_diff("#{Issue.table_name}.easy_status_updated_on", "'#{Issue.connection.quoted_date(Time.now)}'"))
  end

  def sql_for_project_is_closed_field(field, operator, value)
    o = value.first == '1' ? '=' : '<>'
    "(#{Project.table_name}.status #{o} #{Project::STATUS_CLOSED})"
  end

  def sql_for_issue_id_field(field, operator, value)
    if operator == '='
      # accepts a comma separated list of ids
      ids = value.first.to_s.scan(/\d+/).map(&:to_i)
      if ids.present?
        "#{Issue.table_name}.id IN (#{ids.join(',')})"
      else
        '1=0'
      end
    else
      sql_for_field('id', operator, value, Issue.table_name, 'id')
    end
  end

  def sql_for_child_field(field, operator, value)
    case operator
    when '=', '!'
      parent_ids = Issue.where(id: value).distinct.pluck(:parent_id)
      if parent_ids.any?
        "#{Issue.table_name}.id #{ operator == '=' ? 'IN' : 'NOT IN' } (#{parent_ids.join(',')})"
      end
    when '*', '!*'
      "#{Issue.table_name}.rgt - #{Issue.table_name}.lft #{ operator == '*' ? '>' : '=' } 1"
    end
  end

  def sql_for_author_by_group_field(field, operator, value)
    if operator == '*' # Any group
      groups   = Group.givable
      operator = '=' # Override the operator since we want to find by assigned_to
    elsif operator == '!*'
      groups   = Group.givable
      operator = '!' # Override the operator since we want to find by assigned_to
    else
      groups = Group.where(:id => value)
    end

    members_of_groups = groups.visible.joins(:users).distinct.pluck('users_users.id')

    sql = '(' + sql_for_field('author_id', operator, members_of_groups, Issue.table_name, 'author_id', false) + ')'
    sql
  end

  def sql_for_author_by_role_field(field, operator, value)
    neg = false
    case operator
    when '!'
      neg      = true
      operator = '='
    when '!*'
      neg      = true
      operator = '*'
    end
    role_sql = sql_for_field('role_id', operator.sub('!', ''), value, MemberRole.table_name, 'role_id')
    base_sql = "SELECT 1 FROM #{MemberRole.table_name} INNER JOIN #{Member.table_name} ON #{Member.table_name}.id = #{MemberRole.table_name}.member_id\
                WHERE #{Issue.table_name}.project_id = #{Member.table_name}.project_id AND #{Issue.table_name}.author_id = #{Member.table_name}.user_id"
    sql      = ["#{neg ? 'NOT ' : ''}EXISTS (#{base_sql} AND #{role_sql})"]
    if value.include?(Role.non_member.id.to_s)
      sql << "#{neg ? '' : 'NOT '}EXISTS (#{base_sql})"
    end
    "(#{sql.join(neg ? ' AND ' : ' OR ')})"
  end

end
