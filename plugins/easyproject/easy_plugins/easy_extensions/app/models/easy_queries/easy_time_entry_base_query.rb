class EasyTimeEntryBaseQuery < EasyQuery

  def self.permission_view_entities
    :view_time_entries
  end

  def query_after_initialize
    super
    self.groups_opened = false if self.new_record?

    self.display_project_column_if_project_missing = false
  end

  def additional_statement
    unless @additional_statement_added
      @additional_statement = self.project.project_condition(Setting.display_subprojects_issues?) if self.project
      unless User.current.allowed_to_globally_view_all_time_entries?
        @additional_statement = +@additional_statement
        @additional_statement << ' AND ' unless @additional_statement.blank?
        @additional_statement << "#{TimeEntry.table_name}.user_id = #{User.current.id}"
      end
      @additional_statement_added = true
    end
    @additional_statement
  end

  def initialize_available_filters
    on_filter_group(l(:label_filter_group_easy_time_entry_query)) do
      add_available_filter 'spent_on', { type: :date_period, order: 1 }
      add_available_filter 'activity_id', { type: :list, order: 10,
                                            values: (project ? proc { project.activities.collect { |i| [i.name, i.id.to_s] } } : proc { TimeEntryActivity.shared.sorted.collect { |i| [i.name, i.id.to_s] } }) }
      add_available_filter 'tracker_id', { type: :list, order: 11,
                                           values: (project ? proc { project.trackers.collect { |t| [t.name, t.id.to_s] } } : proc { Tracker.all.collect { |t| [t.name, t.id.to_s] } }) }
      add_available_filter 'created_on', { type: :date_period, order: 12 }
      add_available_filter 'updated_on', { type: :date_period, order: 17 }
      add_available_filter 'xentity_type', { type:   :list,
                                             values: proc {
                                               TimeEntry.available_entity_types.map { |t| [l('label_' + t.underscore), t] }.sort_by { |m| m[0] }
                                             },
                                             order:  17,
                                             name:   l(:field_entity_type) }
      if User.current.internal_client?
        add_available_filter 'user_roles', { type: :list, order: 9, values: proc { Role.givable.sorted.collect { |r| [r.name, r.id.to_s] } } }
      end
      add_available_filter 'updated_on', { type: :date_period, order: 23 }
      add_available_filter 'issue_id', { type: :list_autocomplete, order: 24, source: 'issue_autocomplete', source_root: 'entities', source_options: { project_id: project&.id } }
      add_available_filter 'easy_external_id', { type: :string }

      if TimeEntry.easy_locking_enabled?
        add_available_filter 'easy_locked', { type: :boolean, order: 20, name: l(:field_locked) }
        add_available_filter 'easy_locked_at', { type: :date_period, order: 21, name: l(:field_locked_at) }
        add_principal_autocomplete_filter 'easy_locked_by_id', { order: 22, name: l(:field_locked_by) }
      end

      unless project
        add_available_filter 'xproject_id', { type: :list_optional, order: 5, values: proc { self.projects_for_select(Project.visible(User.current, include_archived: true).non_templates.sorted) }, name: l(:field_project), data_type: :project }
        add_available_filter 'xproject_name', { type: :text, order: 6, name: l(:label_project_name) }
        add_available_filter 'parent_id', { type: :list, order: 7, values: proc { self.projects_for_select(Project.visible(User.current, include_archived: true).non_templates.sorted) }, data_type: :project }
        add_available_filter 'project_root_id', { type: :list, order: 8, values: proc { self.projects_for_select(Project.visible(User.current, include_archived: true).non_templates.sorted.roots.select([:id, :name, :easy_level, :parent_id]).to_a, false) }, data_type: :project }
        add_available_filter 'subprojects_of',
                             { type:      :list,
                               name:      "#{l(:field_subprojects_of)} (#{l('easy_query.name.easy_project_query')})",
                               values:    proc { all_projects_parents_values },
                               data_type: :project,
                               includes:  [:project] }
      end

      if User.current.allowed_to_globally_view_all_time_entries?
        add_principal_autocomplete_filter 'user_id', { order: 15, includes: [:user] }
        add_available_filter 'user_group', { type: :list, order: 15, name: l(:label_group), values: proc { all_groups_values } }
      end
    end

    on_filter_group(l(:label_filter_group_easy_issue_query)) do
      add_available_filter 'issue_created_on', { type: :date_period, order: 13 }
      add_available_filter 'issue_updated_on', { type: :date_period, order: 14 }
      add_available_filter 'issue_closed_on', { type: :date_period, order: 15 }
      add_available_filter 'issue_open_duration_in_hours', { type: :float, order: 16 }
      add_available_filter 'issue_easy_external_id', { type: :string, name: l(:field_easy_external), order: 17 }
      add_principal_autocomplete_filter 'issue_assigned_to_id', { klass: User, name: l(:field_assigned_to) }
      versions = proc {
        if project
          Version.values_for_select_with_project(project.shared_versions)
        else
          Version.values_for_select_with_project(Version.visible.where(projects: { easy_is_easy_template: false }).joins(:project))
        end
      }
      add_available_filter 'fixed_version_id', { type: :list_optional, order: 17, values: versions, data_type: :version }
      add_available_filter 'issue_parent_id', { type: :list_autocomplete, klass: Issue, order: 24, source: 'issue_autocomplete', source_root: 'entities' }
    end

    add_custom_fields_filters(TimeEntryCustomField.visible.sorted)
    add_custom_fields_filters(UserCustomField.visible.sorted, :user)

    add_associations_custom_fields_filters :project
    add_custom_fields_filters(issue_custom_fields, :issue)

    # CF are already included via `add_associations_custom_fields_filters`
    add_associations_filters EasyProjectQuery, skip_all_cf: true
  end

  def available_columns
    unless @available_columns_added
      group              = l(:label_filter_group_easy_time_entry_query)
      group_issue        = l(:label_filter_group_easy_issue_query)
      group_user         = l(:label_user_plural)
      @available_columns = [
          EasyQueryDateColumn.new(:spent_on, :sortable => "#{TimeEntry.table_name}.spent_on", :groupable => true, :group => group),
          EasyQueryColumn.new(:tweek, :sortable => "#{TimeEntry.table_name}.tweek", :groupable => true, :group => group),
          EasyQueryColumn.new(:tmonth, :sortable => "#{TimeEntry.table_name}.tmonth", :groupable => true, :group => group),
          EasyQueryColumn.new(:tyear, :sortable => "#{TimeEntry.table_name}.tyear", :groupable => true, :group => group),
          EasyQueryColumn.new(:user, :groupable => "#{TimeEntry.table_name}.user_id", :sortable => lambda { User.fields_for_order_statement }, :includes => [:user => :easy_avatar], :group => group_user),
          EasyQueryColumn.new(:activity, :groupable => true, :sortable => "#{TimeEntryActivity.table_name}.name", :group => group),
          EasyQueryColumn.new(:issue, :sortable => "#{Issue.table_name}.subject", :groupable => "#{Issue.table_name}.id", :preload => [:issue => [:priority, :status, :tracker, :project, :assigned_to]], :group => group_issue),
          EasyQueryColumn.new(:tracker, :sortable => "#{Tracker.table_name}.position", :groupable => "#{Tracker.table_name}.id", :includes => [{ :issue => :tracker }], :group => group),
          EasyQueryColumn.new(:fixed_version, :sortable => lambda { Version.fields_for_order_statement }, :includes => [:issue => :fixed_version], :group => group),
          EasyQueryColumn.new(:project, :sortable => "#{Project.table_name}.name", :groupable => "#{Project.table_name}.id", :group => group),
          EasyQueryColumn.new(:parent_project, :sortable => 'join_parent.name', :groupable => "join_parent.id", :joins => joins_for_parent_project_field, :group => group),
          EasyQueryColumn.new(:project_root,
                              :sortable    => "(SELECT p.id FROM #{Project.table_name} p WHERE p.lft <= #{Project.table_name}.lft AND p.rgt >= #{Project.table_name}.rgt AND p.parent_id IS NULL)",
                              :sumable_sql => "(SELECT p.id FROM #{Project.table_name} p WHERE p.lft <= #{Project.table_name}.lft AND p.rgt >= #{Project.table_name}.rgt AND p.parent_id IS NULL)",
                              :groupable   => true, :group => group),
          # :sumable_sql => "(SELECT r.role_id FROM member_roles r INNER JOIN members m ON m.id = r.member_id WHERE m.project_id = #{TimeEntry.table_name}.project_id AND m.user_id = #{TimeEntry.table_name}.user_id)"
          EasyQueryColumn.new(:comments, :group => group),
          EasyQueryColumn.new(:hours, :sortable => "#{TimeEntry.table_name}.hours", :sumable => :bottom, :caption => 'label_spent_time', :group => group),
          EasyQueryColumn.new(:easy_range_from, :group => group),
          EasyQueryColumn.new(:easy_range_to, :group => group),
          EasyQueryDateColumn.new(:created_on, :sortable => "#{TimeEntry.table_name}.created_on", :group => group),
          EasyQueryDateColumn.new(:updated_on, :sortable => "#{TimeEntry.table_name}.updated_on", :group => group),
          EasyQueryColumn.new(:easy_external_id, :caption => :field_easy_external, :group => group),
          EasyQueryColumn.new(:issue_assigned_to, :sortable => lambda { User.fields_for_order_statement('join_assignee') }, :groupable => "#{Issue.table_name}.assigned_to_id", :preload => [:project => [:enabled_modules], :issue => [:assigned_to => Setting.gravatar_enabled? ? :email_addresses : :easy_avatar]], :caption => :field_assigned_to, :group => group_issue),
          EasyQueryDateColumn.new(:issue_created_on, :sortable => "#{Issue.table_name}.created_on", :group => group_issue),
          EasyQueryDateColumn.new(:issue_updated_on, :sortable => "#{Issue.table_name}.updated_on", :group => group_issue),
          EasyQueryDateColumn.new(:issue_closed_on, :sortable => "#{Issue.table_name}.closed_on", :group => group_issue),
          EasyQueryColumn.new(:issue_easy_external_id, :caption => :field_easy_external, :sortable => "#{Issue.table_name}.easy_external_id", :group => group_issue),
          EasyQueryColumn.new(:issue_open_duration_in_hours, :sortable => self.sql_time_diff("#{Issue.table_name}.created_on", "#{Issue.table_name}.closed_on"), :group => group_issue),
          EasyQueryColumn.new(:entity_type, :groupable => true, :sortable => "#{TimeEntry.table_name}.entity_type", :caption => :field_entity_type, :group => group),
          EasyQueryColumn.new(:entity, :caption => :field_entity, :group => group, :preload => [:entity]),
          EasyQueryColumn.new(:category, :sortable => "#{IssueCategory.table_name}.name", :groupable => "#{IssueCategory.table_name}.id", :includes => [{ :issue => :category }], :group => group_issue),
          EasyQueryColumn.new(:'issue.fixed_version',
                              groupable: "#{Version.table_name}.id",
                              sortable: "#{Version.table_name}.name",
                              caption: :label_version,
                              includes: [issue: :fixed_version]),
          EasyQueryColumn.new(:'issue.parent.subject',
                              groupable: "#{Issue.table_name}.parent_id",
                              sortable: 'parents_issues_sort.subject',
                              caption: :field_parent_issue,
                              group: group_issue)
      ]

      if User.current.internal_client?
        @available_columns << EasyQueryColumn.new(:user_roles, groupable: false, group: group)
      end

      if TimeEntry.easy_locking_enabled?
        @available_columns << EasyQueryColumn.new(:easy_locked, :groupable => true, :sortable => "#{TimeEntry.table_name}.easy_locked", :caption => :field_locked, :group => group)
        @available_columns << EasyQueryDateColumn.new(:easy_locked_at, :sortable => "#{TimeEntry.table_name}.easy_locked_at", :caption => :field_locked_at, :group => group)
        @available_columns << EasyQueryColumn.new(:easy_locked_by, :sortable => lambda { User.fields_for_order_statement('locked_by_user') }, :caption => :field_locked_by, :group => group, :preload => [:easy_locked_by])
      end
      if User.current.allowed_to?(:view_estimated_hours, project, { :global => true })
        @available_columns << EasyQueryColumn.new(:estimated_hours, :sortable => "#{Issue.table_name}.estimated_hours", :sumable => :bottom, :sumable_sql => "(SELECT i.estimated_hours FROM #{Issue.table_name} i WHERE i.id = #{TimeEntry.table_name}.issue_id)", :sumable_options => { model: 'Issue', column: 'estimated_hours', distinct_columns: [["#{Issue.table_name}.id", :issue]] }, :group => group)
      end
      @available_columns << EasyQueryColumn.new(:issue_id, :sortable => "#{Issue.table_name}.id", :group => group_issue) if EasySetting.value('show_issue_id', project)

      @available_columns.concat(TimeEntryCustomField.visible.sorted.collect { |cf| EasyQueryCustomFieldColumn.new(cf) })
      @available_columns.concat(issue_custom_fields.visible.sorted.to_a.collect { |cf| EasyQueryCustomFieldColumn.new(cf, group: l(:xml_data_issue_custom_fields), assoc: :issue) })
      @available_columns.concat(ProjectCustomField.visible.where(show_on_list: true).sorted.to_a.collect { |cf| EasyQueryCustomFieldColumn.new(cf, group: l(:label_project_custom_fields), assoc: :project) })
      @available_columns.concat(UserCustomField.visible.sorted.to_a.collect { |cf| EasyQueryCustomFieldColumn.new(cf, group: l(:label_user_custom_fields), assoc: :user) })

      @available_columns_added = true
    end
    @available_columns
  end

  def joins_for_issue_assignee
    issue          = Issue.arel_table
    assignee       = User.arel_table.alias('join_assignee')
    join_assignees = issue.create_on(issue[:assigned_to_id].eq(assignee[:id]))

    issue.create_join(assignee, join_assignees, Arel::Nodes::OuterJoin).to_sql
  end

  def columns_with_me
    super + ['issue_assigned_to_id', 'easy_locked_by_id']
  end

  def entity
    TimeEntry
  end

  def entity_scope
    @entity_scope ||= TimeEntry.non_templates.visible_with_archived
  end

  def self.chart_support?
    true
  end

  def default_find_include
    [:project, :user, :issue, :activity]
  end

  def default_find_preload
    outputs.include?('list') ? [:easy_attendance] : []
  end

  def default_sort_criteria
    @default_sort_criteria ||= super.presence || [['spent_on', 'desc']]
  end

  def additional_group_attributes(group, attributes, options = {})
    @total_hours                      ||= self.entity_sum("#{TimeEntry.table_name}.hours")
    @column_for_additional_attributes ||= available_columns.detect { |col| col.name == :hours }
    sum                               = attributes[:sums][:bottom][@column_for_additional_attributes]
    attributes[:percent]              = ((sum / @total_hours) * 100.0).round(2) if sum && !@total_hours.zero?
  end

  def add_additional_order_statement_joins(order_options)
    joins = []
    if order_options
      if order_options.include?('join_parent') && col = available_columns.detect { |col| (col.name == :parent_project) }
        joins << col.joins
      end
      if order_options.include?('locked_by_user')
        joins << "LEFT OUTER JOIN #{User.table_name} locked_by_user ON locked_by_user.id = #{TimeEntry.table_name}.easy_locked_by_id"
      end
      if order_options.include?('join_assignee') && col = available_columns.detect { |col| (col.name == :issue_assigned_to) }
        joins << joins_for_issue_assignee
      end
      if order_options.include?('parents_issues_sort')
        joins << "LEFT OUTER JOIN #{Issue.table_name} parents_issues_sort ON #{Issue.table_name}.parent_id = parents_issues_sort.id"
      end
    end
    joins
  end

  def issue_custom_fields
    if project
      project.all_issue_custom_fields
    else
      IssueCustomField.all
    end
  end

  def get_custom_sql_for_field(field, operator, value)
    case field
    when 'activity_id'
      db_table = TimeEntry.table_name
      db_field = 'activity_id'
      sql      = "#{db_table}.activity_id #{ operator == '=' ? 'IN' : 'NOT IN' } (SELECT #{TimeEntryActivity.table_name}.id FROM #{TimeEntryActivity.table_name} WHERE "
      sql << sql_for_field(field, '=', value, TimeEntryActivity.table_name, 'parent_id')
      sql << ' OR '
      sql << sql_for_field(field, '=', value, db_table, db_field) + ')'
      return sql
    when 'user_roles'
      v   = value.is_a?(Array) ? value.map(&:to_i).join(',') : value.to_i
      o   = (operator == '=') ? 'IN' : 'NOT IN'
      sql = "EXISTS (SELECT r.id FROM member_roles r INNER JOIN members m ON m.id = r.member_id WHERE m.user_id = #{User.table_name}.id AND m.project_id = #{TimeEntry.table_name}.project_id AND r.role_id #{o} (#{v}))"
      return sql
    when 'user_group'
      o = (operator == '=') ? '' : 'NOT'
      return "#{o} 0 = 1" if value.blank?
      v   = value.is_a?(Array) ? value.map(&:to_i).join(',') : value.to_i
      sql = "#{o} EXISTS (SELECT r.user_id FROM groups_users r WHERE #{User.table_name}.id = r.user_id AND group_id IN (#{v}))"
    when 'project_root_id'
      db_table = TimeEntry.arel_table
      db_field = 'project_id'
      v        = Project.select('children.id').where(:id => value).joins('INNER JOIN projects as children ON children.lft >= projects.lft AND children.rgt <= projects.rgt').where(Project.allowed_to_condition(User.current, :view_time_entries, { :table_name => 'children', :include_archived => true })).to_sql

      if operator == '='
        db_table[db_field.to_sym].in(Arel.sql(v)).to_sql
      else
        db_table[db_field.to_sym].not_in(Arel.sql(v)).to_sql
      end
    when 'parent_id'
      ids = Array(values_for('parent_id')).map(&:to_i)
      return '' if ids.blank?
      op_not = (operator_for('parent_id') == '!')
      return "#{Project.table_name}.id #{op_not ? 'NOT IN' : 'IN'} (SELECT p_parent_id.id FROM #{Project.table_name} p_parent_id WHERE p_parent_id.parent_id IN (#{ids.join(',')}))"
    when 'subprojects_of'
      sql_for_subprojects_of_field(field, operator, value)
    when 'issue_open_duration_in_hours'
      sql_for_issue_open_duration_in_hours_field(field, operator, value)
    when 'issue_parent_id'
      sql_for_issue_parent_id_field(field, operator, value)
    when /^issue_cf_(d*)/
      nil
    when /^issue_(.*)/
      sql_for_field(field, operator, value, Issue.table_name, $1)
    end
  end

  def sql_for_subprojects_of_field(field, operator, value)
    ids = Array.wrap(value).select(&:present?).map(&:to_i)
    projects = Project.table_name
    if ids.any? && (projects_tree = Project.where(id: ids).pluck(:lft, :rgt)).any?
      projects_tree.map! do |lft, rgt|
        "(#{projects}.lft >= #{lft} AND #{projects}.rgt <= #{rgt})"
      end
      projects_tree_condition = projects_tree.join(' OR ')
      sql_op = (operator == '!') ? 'NOT IN' : 'IN'
      return "(#{projects}.id #{sql_op} (SELECT asubp.id FROM #{projects} asubp WHERE #{projects_tree_condition}))"
    end
  end

  def sql_for_issue_parent_id_field(field, operator, value)
    case operator
    when '=', '!'
      values = Array.wrap(value).select(&:present?)
      if values.any? && (issues_self_and_descendants_tree = Issue.where(id: values).pluck(:root_id, :lft, :rgt)).any?
        issues = Issue.arel_table
        issues_self_and_descendants_tree.map! do |root_id, lft, rgt|
          issues[:root_id].eq(root_id).and(issues[:lft].gteq(lft)).and(issues[:rgt].lteq(rgt)).to_sql
        end
        issues_self_and_descendants_tree = issues_self_and_descendants_tree.join(' OR ')
        if operator == '!'
          issues_self_and_descendants_tree = "(NOT (#{issues_self_and_descendants_tree}) OR #{TimeEntry.table_name}.issue_id IS NULL)"
        end
        return issues_self_and_descendants_tree
      end
    when '!*'
      # if none, return time entries from all tasks which have no parents
      "#{Issue.table_name}.parent_id IS NULL"
    when '*'
      # if any, return time entries from all tasks which have parents
      "#{Issue.table_name}.parent_id IS NOT NULL"
    end
  end

  def sql_for_xproject_id_field(field, operator, v)
    db_table               = self.entity.table_name
    db_field               = 'project_id'
    returned_sql_for_field = self.sql_for_field(db_field, operator, v, db_table, db_field)
    return ('(' + returned_sql_for_field + ')') unless returned_sql_for_field.blank?
  end

  def sql_for_xproject_name_field(field, operator, v)
    db_table               = Project.table_name
    db_field               = 'name'
    returned_sql_for_field = self.sql_for_field(db_field, operator, v, db_table, db_field)
    return ('(' + returned_sql_for_field + ')') unless returned_sql_for_field.blank?
  end

  def sql_for_tracker_id_field(field, operator, v)
    db_table               = Issue.table_name
    db_field               = field
    returned_sql_for_field = self.sql_for_field(field, operator, v, db_table, db_field)
    return ('(' + returned_sql_for_field + ')') unless returned_sql_for_field.blank?
  end

  def sql_for_fixed_version_id_field(field, operator, v)
    db_table               = Issue.table_name
    db_field               = field
    returned_sql_for_field = self.sql_for_field(field, operator, v, db_table, db_field)
    return ('(' + returned_sql_for_field + ')') unless returned_sql_for_field.blank?
  end

  def sql_for_issue_open_duration_in_hours_field(field, operator, value)
    sql_for_field(field, operator, value, nil, self.sql_time_diff("#{Issue.table_name}.created_on", "#{Issue.table_name}.closed_on"))
  end

  def sql_for_issue_easy_external_id_field(field, operator, value)
    sql_for_field(field, operator, value, Issue.table_name, 'easy_external_id')
  end

  def sql_for_issue_assigned_to_id_field(field, operator, value)
    sql_for_field(field, operator, value, Issue.table_name, 'assigned_to_id')
  end

  def sql_for_xentity_type_field(field, operator, value)
    db_table               = self.entity.table_name
    db_field               = 'entity_type'
    returned_sql_for_field = self.sql_for_field(field, operator, value, db_table, db_field)
    return ('(' + returned_sql_for_field + ')') unless returned_sql_for_field.blank?
  end
end
