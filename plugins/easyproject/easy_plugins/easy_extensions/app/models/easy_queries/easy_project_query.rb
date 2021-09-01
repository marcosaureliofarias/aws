class EasyProjectQuery < EasyQuery

  def self.entity_css_classes(project, options = {})
    project.css_classes(project.easy_level, options)
  end

  def self.permission_view_entities
    :view_project
  end

  def entity_easy_query_path(options)
    options = options.dup
    polymorphic_path(self.entity, options)
  end

  def query_after_initialize
    super
    self.display_filter_sort_on_edit = true
  end

  def filter_groups_ordering
    super + [
        EasyQuery.column_filter_group_name(nil)
    ]
  end

  def column_groups_ordering
    super + [
        EasyQuery.column_filter_group_name(nil),
        l(:label_filter_group_easy_time_entry_query),
        l(:label_user_plural)
    ]
  end

  def entity_context_menu_path(options = {})
    context_menus_projects_path
  end

  def initialize_available_filters
    on_filter_group(default_group_label) do

      if self.entity == Project
        add_available_filter 'project_id', {
            type:      :list_autocomplete,
            order:     1,
            source: 'visible_projects',
            source_root: 'projects',
            data_type: :project,
            klass: Project
        }
      end

      add_available_filter('parent_id', {
          type:      :list,
          label:     :field_is_subproject_of,
          order:     1,
          values:    proc { all_projects_parents_values },
          data_type: :project
      })

      if User.current.internal_client?
        add_available_filter('role_id', {
            type: :list,
            order: 6,
            values: Proc.new { Role.sorted.collect { |r| [r.name, r.id.to_s] } }
        })
      end
      add_available_filter('name', { type: :text, order: 8 })
      add_available_filter('is_planned', {
          type: :boolean,
          order: 9
      })
      add_available_filter('is_closed', {
          type: :boolean,
          order: 10,
          name: l(:field_is_project_closed)
      })
      add_available_filter('is_public', {
          type: :boolean,
          order: 11
      })
      add_available_filter('created_on', { type: :date_period, order: 12 })
      add_available_filter('updated_on', { type: :date_period, order: 13 })
      add_available_filter('not_updated_on', { type: :date_period, time_column: true, order: 14, name: l(:label_not_updated_on) })
      add_available_filter('easy_start_date', { type: :date_period, order: 15 }) unless EasySetting.value('project_calculate_start_date')
      add_available_filter('easy_due_date', { type: :date_period, order: 16 }) unless EasySetting.value('project_calculate_due_date')
      add_available_filter('favorited', { type: :boolean, order: 17 })
      add_available_filter('easy_external_id', { type: :string, order: 18 })
      add_principal_autocomplete_filter 'member_id', { attr_reader: true, attr_writer: true }
      add_principal_autocomplete_filter 'author_id', { attr_reader: true, attr_writer: true }
      add_principal_autocomplete_filter 'default_assigned_to_id', { attr_reader: true, attr_writer: true }
      add_available_filter 'easy_indicator', { type: :list, order: 19, values: Proc.new do
        easy_indicator_values = []
        easy_indicator_values << [l(:ok, scope: :easy_indicator), Project::EASY_INDICATOR_OK.to_s]
        easy_indicator_values << [l(:warning, scope: :easy_indicator), Project::EASY_INDICATOR_WARNING.to_s]
        easy_indicator_values << [l(:alert, scope: :easy_indicator), Project::EASY_INDICATOR_ALERT.to_s]
        easy_indicator_values
      end
      }
      add_available_filter 'tags', { type: :list_autocomplete, label: :label_easy_tags, source: 'tags', source_root: '' }
      add_available_filter 'easy_priority_id', { type: :list, label:  :field_priority,
                                                 values: proc { EasyProjectPriority.active.sorted.select(:name, :id).map { |p| [p.name, p.id] } }
      }
      add_available_filter 'has_enabled_modules', type: :list_optional, label: :label_project_has_module,
                           values: proc { Redmine::AccessControl.available_project_modules.collect { |m| [l_or_humanize(m, prefix: "project_module_"), m.to_s] } }
      add_available_filter 'scheduled_for_destroy', type: :boolean, label: :label_project_scheduled_for_destroy
    end
    add_custom_fields_filters(ProjectCustomField)
  end

  def initialize_available_columns
    sortable_due_date  = EasySetting.value('project_calculate_due_date') ? nil : "#{Project.table_name}.easy_due_date"
    sortable_start_date = EasySetting.value('project_calculate_start_date') ? nil : "#{Project.table_name}.easy_start_date"

    on_column_group(default_group_label) do
      add_available_column 'name', sortable: "#{Project.table_name}.name"
      add_available_column 'parent', preload: [:parent]
      add_available_column 'root'
      add_available_column 'description', sortable: "#{Project.table_name}.description", inline: true
      add_available_column 'status', groupable: "#{Project.table_name}.status", sortable: "#{Project.table_name}.status", default_order: 'desc'
      add_available_column EasyQueryDateColumn.new(:start_date, sortable: sortable_start_date, filter: :easy_start_date)
      add_available_column EasyQueryDateColumn.new(:due_date, sortable: sortable_due_date, filter: :easy_due_date)
      add_available_column EasyQueryDateColumn.new(:created_on, sortable: "#{Project.table_name}.created_on", default_order: 'desc')
      add_available_column EasyQueryDateColumn.new(:updated_on, sortable: "#{Project.table_name}.updated_on", default_order: 'desc')
      add_available_column 'journal_comments', inline: true, caption: :field_project_journal_comments
      add_available_column 'last_journal_comment', inline: true, caption: :field_project_last_journal_comment
      add_available_column 'easy_indicator'
      add_available_column 'completed_percent'
      add_available_column 'tags', preload: [:tags], caption: :label_easy_tags
      add_available_column 'priority', caption: :field_priority, groupable: "#{Project.table_name}.easy_priority_id", preload: [:priority], sortable: 'easy_project_priority.position'
      add_available_column 'easy_external_id', caption: :field_easy_external

      add_available_column 'id', sortable: "#{Project.table_name}.id"
      if EasySetting.value('project_display_identifiers')
        add_available_column 'identifier', sortable: "#{Project.table_name}.identifier"
      end
    end

    on_column_group(l('label_filter_group_easy_time_entry_query')) do
      if User.current.allowed_to?(:view_estimated_hours, project, { global: true })
        add_available_column 'sum_estimated_hours', caption: :field_estimated_hours, numeric: true, sumable_sql: sum_estimated_hours_sql_sum, sumable: :both
        add_available_column 'total_sum_estimated_hours', caption: :field_sum_estimated_hours, numeric: true
      end

      if User.current.allowed_to?(:view_time_entries, project, { global: true })
        add_available_column 'sum_of_timeentries', numeric: true, sumable_sql: sum_of_timeentries_sql_sum, sumable: :both
        if User.current.allowed_to?(:view_estimated_hours, project, { global: true })
          add_available_column 'remaining_timeentries', numeric: true, sumable_sql: remaining_timeentries_sql_sum, sumable: :both
          add_available_column 'total_remaining_timeentries'
        end
        add_available_column 'total_spent_hours', default_order: 'desc', caption: :label_total_spent_time
      end
    end

    ProjectCustomField.visible.where(show_on_list: true).sorted.each do |cf|
      add_available_column EasyQueryCustomFieldColumn.new(cf)
    end

    on_column_group(l('label_user_plural')) do
      add_available_column 'author', groupable: true, sortable: lambda { User.fields_for_order_statement('authors') }, preload: [{ author: :easy_avatar }]
      add_available_column 'default_assigned_to', groupable: true, sortable: lambda { User.fields_for_order_statement('default_assignees') }, preload: [{ default_assigned_to: :easy_avatar }]
      add_available_column 'users', caption: :field_member
    end
  end

  def additional_statement
    unless @additional_statement_added
      @additional_statement = super
      @additional_statement << ' AND ' unless @additional_statement.blank?
      @additional_statement << Project.arel_table[:easy_is_easy_template].eq(false).to_sql
      @additional_statement_added = true
    end
    @additional_statement
  end

  def searchable_columns
    return ["#{Project.table_name}.name"]
  end

  def calendar_support?
    true
  end

  def self.chart_support?
    true
  end

  def entity
    Project
  end

  def columns_with_me
    super + ['member_id', 'default_assigned_to_id']
  end

  def extended_period_options
    {
        :extended_options       => [:to_today],
        :option_limit           => {
            :is_null        => ['easy_due_date', 'easy_start_date'],
            :is_not_null    => ['easy_due_date', 'easy_start_date'],
            :after_due_date => ['easy_due_date'],
            :next_week      => ['easy_due_date'],
            :tomorrow       => ['easy_due_date'],
            :next_5_days    => ['easy_due_date'],
            :next_7_days    => ['easy_due_date'],
            :next_10_days   => ['easy_due_date'],
            :next_30_days   => ['easy_due_date'],
            :next_90_days   => ['easy_due_date'],
            :next_month     => ['easy_due_date'],
            :next_year      => ['easy_due_date']
        },
        :field_disabled_options => {
            'not_updated_on' => [:is_null, :is_not_null]
        }
    }
  end

  def default_sort_criteria
    @default_sort_criteria ||= super.presence || [['lft', 'asc']]
  end

  def default_find_preload
    preloads = [:enabled_modules, { parent: :enabled_modules }]
    preloads << :project_custom_fields if has_custom_field_column?
    preloads
  end

  def preloads_for_entities(projects)
    project_ids = projects.map(&:id)
    if has_column?(:sum_of_timeentries) || has_column?(:remaining_timeentries)
      hours_by_project_id = TimeEntry.where(:project_id => project_ids).group(:project_id).sum(:hours)
      projects.each do |project|
        project.instance_variable_set "@sum_time_entries", (hours_by_project_id[project.id] || 0.0)
      end
    end
    if has_column?(:sum_estimated_hours) || has_column?(:remaining_timeentries)
      hours_by_project_id = Issue.where(:project_id => project_ids).group(:project_id).sum(:estimated_hours)
      projects.each do |project|
        project.instance_variable_set "@sum_estimated_hours", (hours_by_project_id[project.id] || 0.0)
      end
    end
    if outputs.include?('list')
      favorited = EasyFavorite.where(entity_id: project_ids, entity_type: 'Project', user: User.current).pluck(:entity_id)
      projects.each do |project|
        project.instance_variable_set "@favorited", true if favorited.include?(project.id)
      end
    end
  end

  def entities(options = {})
    projects = super(options)
    preloads_for_entities(projects)
    projects
  end

  def entities_for_group(group, options = {})
    projects = super
    preloads_for_entities(projects)
    projects
  end

  def sortable_columns
    { 'lft' => "#{Project.table_name}.lft" }.merge(super)
  end

  def roots(options = {})
    projects           = Project.arel_table
    root_statement     = statement
    children           = Arel::Table.new(:projects, :as => :children)
    children_statement = root_statement.gsub(/^projects\.|(?<=[^_])projects\./, 'children.')
    children_statement.gsub!(/FROM projects (AS)?/i) { |m|
      if $1
        'FROM projects AS'
      else
        'FROM projects AS children '
      end
    }

    join_sources = projects.join(children, Arel::Nodes::OuterJoin).on(
        projects[:lft].lteq(children[:lft]).and(
            children[:parent_id].not_eq(nil).and(
                projects[:rgt].gteq(children[:rgt])
            )
        )
    ).join_sources

    root_info = merge_scope(Project, options)
                    .select('projects.id AS root_id, Count(children.id) AS children_count')
                    .joins(join_sources)
                    .where("( (#{root_statement}) OR (#{children_statement}) ) AND projects.parent_id IS NULL")
                    .reorder(:lft)
                    .group('projects.id')

    root_hash = Hash[root_info.map { |r| [r.root_id.to_i, r.children_count.to_i] }]
    return root_hash, Project.where(:id => root_hash.keys).reorder(:lft)
  end

  def use_visible_condition?
    true
  end

  def set_entity_scope_for_projects(params)
    @entity_scope_for_projects = get_referenced_collection_params(params)
  end

  def find_projects_for_root(root_id = nil, options = {})
    projects = children_scope(root_id).
        select(Project.arel_table[Arel.star]).select("MIN(children.lft) - #{entity_table_name}.lft AS diff").
        select("(COUNT(children.id) - CASE WHEN MIN(children.lft) > #{entity_table_name}.lft THEN 0 ELSE 1 END) AS visible_children").
        group(:id)

    ids_with_children = projects.map { |i| [i.id, i.visible_children] }.to_h
    ids_with_diff     = projects.map { |i| [i.id, i.diff] }.to_h

    project_statement = "#{statement}"
    project_statement << " AND #{Project.visible_condition(User.current)}" if use_visible_condition?
    second_part_of_statement = Project.arel_table[:parent_id].eq(root_id).and(Arel.sql(project_statement))
    second_part_of_statement = second_part_of_statement.and(Arel.sql("#{Project.table_name}.id IN (#{@entity_scope_for_projects.select(:id).to_sql})")) if @entity_scope_for_projects
    all_ids_statement = Project.arel_table[:id].in(ids_with_children.keys).or(second_part_of_statement).to_sql
    project_scope     = Project.where(all_ids_statement).limit(options[:limit]).offset(options[:offset]).order(options[:order])

    if additional_scope
      project_scope         = project_scope.merge(additional_scope)
      self.additional_scope = nil
    end

    @projects_for_root_scope = new_entity_scope(project_scope)
    @projects_for_root_scope.to_a.each do |p|
      p.has_visible_children = ids_with_children[p.id].to_i > 0
      p.nofilter             = ' nofilter' if ids_with_diff[p.id].to_i > 0
    end
    preloads_for_entities(@projects_for_root_scope)
    @projects_for_root_scope
  end

  def children_scope(root_id = nil)
    @entity_table_name = 'children'
    children_statement = self.statement
    @entity_table_name = nil
    s                  = Project.joins('INNER JOIN projects as children ON children.lft >= projects.lft AND children.rgt <= projects.rgt').
        where(children_statement).where(parent_id: root_id).
        where.not(children: { parent_id: root_id })
    s                  = s.where(children: { id: @entity_scope_for_projects.select(:id) } ) if @entity_scope_for_projects
    s                  = s.where(Project.visible_condition(User.current, table_name: 'children')) if use_visible_condition?
    s
  end

  def only_favorited?
    filters.include?('favorited')
  end

  def display_as_tree?
    if !(sort_criteria.blank? || sort_criteria == [['lft', 'asc']]) || grouped? || free_search_question
      false
    else
      true
    end
  end

  def from_params(params)
    super

    easy_query_q = params['easy_query_q'] if params.present?
    process_term(easy_query_q) if easy_query_q && easy_query_q.empty?
  end

  def generate_custom_formatting_entities_hash
    return if self.custom_formatting.blank?
    self.custom_formatting_entities = {}

    self.custom_formatting.each do |scheme, filters|
      ids_for_scheme = []
      ids_for_scheme |= self.new_entity_scope.where(self.statement(filters)).pluck(:id)
      ids_for_scheme |= @projects_for_root_scope.where(self.statement(filters)).pluck(:id) if @projects_for_root_scope
      ids_for_scheme.each do |project_id|
        self.custom_formatting_entities[project_id] = scheme
      end
    end
  end

  def sql_for_not_updated_on_field(field, operator, value)
    db_field = 'updated_on'
    db_table = entity_table_name

    if operator =~ /date_period_([12])/
      if $1 == '1' && value[:period].to_sym == :all
        "#{db_table}.#{db_field} = #{db_table}.created_on"
      else
        period_dates = self.get_date_range($1, value[:period], value[:from], value[:to], value[:period_days])
        self.reversed_date_clause(db_table, db_field, (period_dates[:from].nil? ? nil : period_dates[:from].beginning_of_day), (period_dates[:to].nil? ? nil : period_dates[:to].end_of_day), field: field)
      end
    else
      nil
    end
  end

  def sql_for_scheduled_for_destroy_field(field, operator, value)
    o = value.first == '1' ? 'IS NOT NULL' : 'IS NULL'
    "(#{entity_table_name}.destroy_at #{o})"
  end

  def statement_skip_fields
    ['member_id', 'role_id', 'parent_id']
  end

  def add_statement_sql_before_filters
    my_fields = ['member_id', 'role_id', 'parent_id'] & filters.keys

    if my_fields.present?
      if my_fields.include?('parent_id')
        parent_id_where = Array.new
        op_not          = (operator_for('parent_id') == '!')
        Project.where(:id => values_for('parent_id')).each do |p|
          if op_not
            parent_id_where << "#{entity_table_name}.id NOT IN (SELECT p_parent_id.id FROM #{Project.table_name} AS p_parent_id WHERE p_parent_id.lft > #{p.lft} AND p_parent_id.rgt < #{p.rgt})"
          else
            parent_id_where << "#{entity_table_name}.id IN (SELECT p_parent_id.id FROM #{Project.table_name} AS p_parent_id WHERE p_parent_id.lft > #{p.lft} AND p_parent_id.rgt < #{p.rgt})"
          end
        end

        if parent_id_where.any?
          if op_not
            sql_parent_id = parent_id_where.join(' AND ')
          else
            sql_parent_id = parent_id_where.join(' OR ')
          end
          sql_parent_id = "(#{sql_parent_id})"
        end
      end

      if my_fields.include?('member_id')
        mv            = personalized_field_value_for_statement('member_id', values_for('member_id').dup)
        sql_member_id = "#{entity_table_name}.id #{operator_for('member_id') == '=' ? 'IN' : 'NOT IN'} (SELECT DISTINCT pm1.project_id FROM #{Member.table_name} pm1 WHERE "
        sql_member_id << sql_for_field('member_id', '=', mv, 'pm1', 'user_id', true)
        sql_member_id << ')'

        if my_fields.include?('role_id')
          sql_member_id << " AND #{entity_table_name}.id #{operator_for('role_id') == '=' ? 'IN' : 'NOT IN'} (SELECT DISTINCT pm1.project_id FROM #{Member.table_name} pm1 INNER JOIN #{MemberRole.table_name} pmr1 ON pmr1.member_id = pm1.id WHERE "
          sql_member_id << sql_for_field('member_id', '=', mv, 'pm1', 'user_id', true)
          sql_member_id << (' AND ' + sql_for_field('role_id', '=', values_for('role_id').dup, 'pmr1', 'role_id', true))
          sql_member_id << ')'
        end
      elsif my_fields.include?('role_id')
        sql_role_id = "#{entity_table_name}.id #{operator_for('role_id') == '=' ? 'IN' : 'NOT IN'} (SELECT DISTINCT pm1.project_id FROM #{Member.table_name} pm1 INNER JOIN #{MemberRole.table_name} pmr1 ON pmr1.member_id = pm1.id WHERE "
        sql_role_id << sql_for_field('role_id', '=', values_for('role_id').dup, 'pmr1', 'role_id', true)
        sql_role_id << ')'
      end

      sql = [sql_parent_id, sql_member_id, sql_role_id].compact.join(' AND ')

      return sql
    end
  end

  def sum_of_timeentries_sql_sum
    "(COALESCE((SELECT SUM(t.hours) FROM #{TimeEntry.table_name} t WHERE t.project_id = #{entity_table_name}.id), 0))"
  end

  def sum_estimated_hours_sql_sum
    "(COALESCE((SELECT SUM(t.estimated_hours) FROM #{Issue.table_name} t WHERE t.project_id = #{entity_table_name}.id), 0))"
  end

  def remaining_timeentries_sql_sum
    "#{sum_estimated_hours_sql_sum} - #{sum_of_timeentries_sql_sum}"
  end

  def sql_for_is_planned_field(field, operator, value)
    o = value.first == '1' ? '=' : '<>'
    "(#{entity_table_name}.status #{o} #{Project::STATUS_PLANNED})"
  end

  def sql_for_is_closed_field(field, operator, value)
    o = value.first == '1' ? '=' : '<>'
    "(#{entity_table_name}.status #{o} #{Project::STATUS_CLOSED})"
  end

  def sql_for_project_id_field(field, operator, value)
    if value.size == 1
      # Accepts a comma separated list of ids
      value = value.first.to_s.scan(/\d+/)
    end

    sql_for_field(field, operator, value, entity_table_name, 'id')
  end

  def sql_for_easy_indicator_field(_field, operator, value)
    sql = []
    op  = (operator == '!') ? 'NOT ' : ''
    return ("#{op}(1=0)") unless value.present?
    ids_in_warning_scope = Project.joins(issues: :status).where.not(issues: { due_date: nil }, issue_statuses: { is_closed: true }).where("#{Issue.table_name}.due_date < ?", Date.today).active_and_planned
    ids_in_alert_scope   = Project.where.not(easy_due_date: nil).where("#{Project.table_name}.easy_due_date < ?", Date.today).active_and_planned

    if Setting.display_subprojects_issues?
      ids_in_warning = ids_in_warning_scope.joins('INNER JOIN projects as ancestors ON ancestors.lft <= projects.lft AND ancestors.rgt >= projects.rgt').distinct.pluck('ancestors.id')
      ids_in_alert   = ids_in_alert_scope.joins('INNER JOIN projects as ancestors ON ancestors.lft <= projects.lft AND ancestors.rgt >= projects.rgt').distinct.pluck('ancestors.id')
    else
      ids_in_warning = ids_in_warning_scope.distinct.pluck(:id)
      ids_in_alert   = ids_in_alert_scope.distinct.pluck(:id)
    end

    ids_not_ok          = ids_in_alert + ids_in_warning
    ids_in_warning_only = ids_in_warning - ids_in_alert

    if value.include?(Project::EASY_INDICATOR_OK.to_s)
      is_easy_due_date_nil_ok = EasySetting.value(:default_project_indicator).to_i == Project::EASY_INDICATOR_OK
      due_date_condition      = (is_easy_due_date_nil_ok || op.present?) ? '' : "#{entity_table_name}.easy_due_date IS NOT NULL AND "
      sql << due_date_condition + (ids_not_ok.any? ? "(#{entity_table_name}.id #{'NOT ' if op.blank?}IN (#{ids_not_ok.join(', ')}))" : '(1=1)')
    end
    if value.include?(Project::EASY_INDICATOR_WARNING.to_s) && ids_in_warning_only.any?
      sql << "(#{entity_table_name}.id #{op}IN (#{ids_in_warning_only.join(', ')}))"
    end
    if value.include?(Project::EASY_INDICATOR_ALERT.to_s) && ids_in_alert.any?
      sql << "(#{entity_table_name}.id #{op}IN (#{ids_in_alert.join(', ')}))"
    end

    sql.any? ? "(#{sql.join(' OR ')})" : '1=0'
  end

  def sql_for_has_enabled_modules_field(_field, operator, value)
    sql     = []
    inverse = true if %w[! !*].include?(operator)
    value.each do |val|
      sql << "#{inverse ? 'NOT ' : ''}EXISTS(#{EnabledModule.where(name: val).where("#{EnabledModule.table_name}.project_id = #{entity_table_name}.id").select('1').to_sql})"
    end
    "( #{sql.join(' AND ')} )"
  end

  def project_order_joins(order_options)
    joins = []
    if order_options.include?('authors')
      joins << "LEFT OUTER JOIN #{User.table_name} authors ON authors.id = #{entity_table_name}.author_id"
    end
    if order_options.include?('default_assignees')
      joins << "LEFT OUTER JOIN #{User.table_name} default_assignees ON default_assignees.id = #{entity_table_name}.default_assigned_to_id"
    end
    if order_options.include?('easy_project_priority')
      joins << "LEFT OUTER JOIN #{EasyProjectPriority.table_name} easy_project_priority ON easy_project_priority.id = #{entity_table_name}.easy_priority_id"
    end
    joins
  end

  def joins_for_order_statement(order_options, return_type = :sql, uniq = true)
    joins = []
    if order_options
      joins.concat(project_order_joins(order_options))
      joins.concat(super(order_options, :array, uniq))
    end

    case return_type
    when :sql
      joins.any? ? joins.join(' ') : nil
    when :array
      joins
    else
      raise ArgumentError, 'return_type has to be either :sql or :array'
    end
  end

end
