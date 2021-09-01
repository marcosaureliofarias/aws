class EasyVersionQuery < EasyQuery
  include ProjectsHelper
  attr_accessor :current_project_id

  def initialize_available_filters
    on_filter_group(default_group_label) do
      add_available_filter 'status', { type: :list, order: 1, values: proc { Version::VERSION_STATUSES.map { |s| [l("version_status_#{s}"), s] } } }
      add_available_filter 'name', { type: :text, order: 2 }
      add_available_filter 'effective_date', { type: :date_period, order: 3 }
      if User.current.internal_client?
        add_available_filter 'role_id', { type: :list, order: 5, values: proc { Role.sorted.map { |r| [r.name, r.id.to_s] } } }
      end
      add_available_filter 'created_on', { type: :date_period, order: 6 }
      add_available_filter 'updated_on', { type: :date_period, order: 7 }
      add_available_filter 'sharing', { type: :list, values: proc { Version::VERSION_SHARINGS.map { |s| [format_version_sharing(s), s] } }, order: 8 }
      add_available_filter 'easy_version_category_id', { type: :list, values: proc { EasyVersionCategory.active.sorted.map { |v| [v.name, v.id] } }, order: 10 }
      add_principal_autocomplete_filter 'member_id', { klass: User, order: 4 }

      if project
        values = proc { projects_for_select(project.self_and_ancestors.visible.non_templates.sorted) }
        add_available_filter 'xproject_id', { type: :list, order: 13, values: values, data_type: :project }
      else
        values = proc { projects_for_select(Project.visible.non_templates.sorted) }
        add_available_filter 'project_id', { type: :list, order: 13, values: values, data_type: :project }
      end
    end

    add_custom_fields_filters(VersionCustomField)
  end

  def easy_query_entity_controller
    self.project ? 'versions' : 'easy_versions'
  end

  def available_columns
    unless @available_columns_added
      group              = default_group_label
      @available_columns = [
          EasyQueryColumn.new(:project, :sortable => "#{Project.table_name}.name", :groupable => "#{Project.table_name}.id", :group => group),
          EasyQueryColumn.new(:status, :sortable => "#{Version.table_name}.status", :groupable => true, :group => group),
          EasyQueryColumn.new(:name, :sortable => "#{Version.table_name}.name", :groupable => true, :group => group),
          EasyQueryDateColumn.new(:effective_date, :sortable => "#{Version.table_name}.effective_date", :groupable => true, :group => group),
          EasyQueryColumn.new(:description, :group => group, :inline => false),
          EasyQueryColumn.new(:easy_version_category, :groupable => "#{EasyVersionCategory.table_name}.id", :sortable => "#{EasyVersionCategory.table_name}.name", :group => group, :includes => [:easy_version_category]),
          EasyQueryColumn.new(:sharing, :sortable => "#{Version.table_name}.sharing", :groupable => true, :group => group),
          EasyQueryDateColumn.new(:created_on, :sortable => "#{Version.table_name}.created_on", :groupable => true, :group => group),
          EasyQueryDateColumn.new(:updated_on, :sortable => "#{Version.table_name}.updated_on", :groupable => true, :group => group),
          EasyQueryColumn.new(:completed_percent, :caption => :field_completed_percent, :group => group)
      ]

      @available_columns.concat(VersionCustomField.sorted.collect { |cf| EasyQueryCustomFieldColumn.new(cf) })

      @available_columns_added = true
    end
    @available_columns
  end

  def default_find_include
    [:project]
  end

  def searchable_columns
    ["#{Version.table_name}.name", "#{Version.table_name}.description"]
  end

  def entity
    Version
  end

  def self.permission_view_entities
    :view_issues
  end

  def self.chart_support?
    true
  end

  def self.report_support?
    false
  end

  def entity_easy_query_path(options)
    p = options[:project] || self.project
    p ? settings_project_path(p, options.merge({tab: 'versions'})) : easy_versions_path(options)
  end

  def entity_scope
    @entity_scope ||= (self.project.nil? ? Version.visible.where(["#{Project.table_name}.easy_is_easy_template = ?", false]) : self.project.shared_versions)
  end

  def extended_period_options
    {
        :extended_options => [:to_today, :is_null, :is_not_null],
        :option_limit     => {
            :after_due_date => ['effective_date'],
            :next_week      => ['effective_date'],
            :tomorrow       => ['effective_date'],
            :next_5_days    => ['effective_date'],
            :next_7_days    => ['effective_date'],
            :next_10_days   => ['effective_date'],
            :next_30_days   => ['effective_date'],
            :next_90_days   => ['effective_date'],
            :next_month     => ['effective_date'],
            :next_year      => ['effective_date']
        }
    }
  end

  protected

  def statement_skip_fields
    ['member_id', 'role_id', 'project_id', 'xproject_id']
  end

  def add_statement_sql_before_filters
    my_fields = ['member_id', 'role_id', 'project_id', 'xproject_id'] & filters.keys

    unless my_fields.blank?
      if my_fields.include?('member_id')
        mv = values_for('member_id').dup
        mv.push(User.current.logged? ? User.current.id.to_s : '0') if mv.delete('me')
        sql_member_id = "#{Project.table_name}.id #{operator_for('member_id') == '=' ? 'IN' : 'NOT IN'} (SELECT DISTINCT pm1.project_id FROM #{Member.table_name} pm1 WHERE "
        sql_member_id << sql_for_field('member_id', '=', mv, 'pm1', 'user_id', true)
        sql_member_id << ')'

        if my_fields.include?('role_id')
          sql_member_id << " AND #{Project.table_name}.id #{operator_for('role_id') == '=' ? 'IN' : 'NOT IN'} (SELECT DISTINCT pm1.project_id FROM #{Member.table_name} pm1 INNER JOIN #{MemberRole.table_name} pmr1 ON pmr1.member_id = pm1.id WHERE "
          sql_member_id << sql_for_field('member_id', '=', mv, 'pm1', 'user_id', true)
          sql_member_id << (' AND ' + sql_for_field('role_id', '=', values_for('role_id').dup, 'pmr1', 'role_id', true))
          sql_member_id << ')'
        end
      elsif my_fields.include?('role_id')
        sql_role_id = "#{Project.table_name}.id #{operator_for('role_id') == '=' ? 'IN' : 'NOT IN'} (SELECT DISTINCT pm1.project_id FROM #{Member.table_name} pm1 INNER JOIN #{MemberRole.table_name} pmr1 ON pmr1.member_id = pm1.id WHERE "
        sql_role_id << sql_for_field('role_id', '=', values_for('role_id').dup, 'pmr1', 'role_id', true)
        sql_role_id << ')'
      end

      if my_fields.include?('project_id')
        sql_project_id = sql_for_project_id_field('project_id', operator_for('project_id'), values_for('project_id').dup)
      end
      if my_fields.include?('xproject_id')
        sql_xproject_id = sql_for_project_id_field('project_id', operator_for('xproject_id'), values_for('xproject_id').dup)
      end

      sql = [sql_member_id, sql_role_id, sql_project_id, sql_xproject_id].compact.join(' AND ')
      sql
    end
  end

  def sql_for_project_id_field(field, operator, v)
    db_table               = self.entity.table_name
    db_field               = 'project_id'
    returned_sql_for_field = self.sql_for_field(db_field, operator, v, db_table, db_field)
    return ('(' + returned_sql_for_field + ')') unless returned_sql_for_field.blank?
  end

end
