class EasyUserQuery < EasyQuery

  def initialize_available_filters
    on_filter_group(default_group_label) do
      add_available_filter 'status', { type: :list, order: 1, values: proc { user_statuses } }
      add_available_filter 'login', { type: :string, order: 7 }
      add_available_filter 'firstname', { type: :string, order: 8 }
      add_available_filter 'lastname', { type: :string, order: 9 }
      add_available_filter 'mail', { type: :string, order: 10, joins: [:email_address] }
      add_available_filter 'easy_user_type', { type: :list, values: proc { EasyUserType.sorted.collect { |t| [t.name, t.id.to_s] } }, order: 11 }
      add_available_filter 'admin', { type: :boolean, order: 12 }
      add_available_filter 'easy_lesser_admin', { type: :boolean, order: 13 }
      add_available_filter 'easy_system_flag', { type: :boolean, order: 14 }
      add_available_filter 'created_on', { type: :date_period, order: 15 }
      add_available_filter 'last_login_on', { type: :date_period, order: 16 }
      add_available_filter 'groups', { type: :list, order: 20, values: proc { Group.sorted.collect { |g| [g.lastname, g.id.to_s] } } }
      add_available_filter 'roles', { type: :list_optional, order: 21, values: proc { Role.sorted.collect { |r| [r.name, r.id.to_s] } } }
      add_available_filter 'auth_source_id', { type: :list_optional, order: 22, values: proc { AuthSource.all.collect { |a| [a.name, a.id.to_s] } } }
      add_available_filter 'easy_external_id', { type: :string, order: 23 }
      add_available_filter 'self_registered', { type: :boolean, order: 24 }
      add_available_filter 'tags', { type: :list_autocomplete, label: :label_easy_tags, source: 'tags', source_root: '' }
      add_available_filter 'updated_on', { type: :date_period, order: 25 }

      add_principal_autocomplete_filter 'user_id', label: :label_user_plural, klass: User
    end

    add_custom_fields_filters(UserCustomField)
  end

  def available_columns
    unless @available_columns_added
      group              = l("label_filter_group_#{self.class.name.underscore}")
      @available_columns = [
          EasyQueryColumn.new(:login, :sortable => "#{User.table_name}.login", :includes => [:easy_avatar], :group => group),
          EasyQueryColumn.new(:firstname, :sortable => "#{User.table_name}.firstname", :groupable => true, :group => group),
          EasyQueryColumn.new(:lastname, :sortable => "#{User.table_name}.lastname", :groupable => true, :group => group),
          EasyQueryColumn.new(:mail, :sortable => "#{EmailAddress.table_name}.address", includes: [:email_address], :group => group),
          EasyQueryColumn.new(:easy_user_type, :sortable => "#{User.table_name}.easy_user_type_id", :groupable => "#{User.table_name}.easy_user_type_id", :includes => [:easy_user_type], :group => group),
          EasyQueryColumn.new(:admin, :sortable => "#{User.table_name}.admin", :groupable => true, :group => group),
          EasyQueryColumn.new(:groups_names, :preload => [:groups], :caption => :label_group_plural, :group => group),
          EasyQueryColumn.new(:easy_lesser_admin, :sortable => "#{User.table_name}.easy_lesser_admin", :groupable => true, :group => group),
          EasyQueryColumn.new(:easy_system_flag, :sortable => "#{User.table_name}.easy_system_flag", :groupable => true, :group => group),
          EasyQueryDateColumn.new(:last_login_on, :sortable => "#{User.table_name}.last_login_on", :groupable => true, :group => group),
          EasyQueryDateColumn.new(:created_on, :sortable => "#{User.table_name}.created_on", :groupable => true, :group => group),
          EasyQueryDateColumn.new(:updated_on, :sortable => "#{User.table_name}.updated_on", :groupable => true, :group => group),
          EasyQueryColumn.new(:roles, :group => group),
          EasyQueryColumn.new(:easy_external_id, :caption => :field_easy_external, :sortable => "#{User.table_name}.easy_external_id", :group => group),
          EasyQueryColumn.new(:qr_code, :group => group),
          EasyQueryColumn.new(:status, :sortable => "#{User.table_name}.status", :groupable => true, :group => group),
          EasyQueryColumn.new(:self_registered, :groupable => "#{User.table_name}.self_registered", :group => group),
          EasyQueryColumn.new(:auth_source, :sortable => "#{AuthSource.table_name}.name", :groupable => "#{User.table_name}.auth_source_id", :includes => [:auth_source], :group => group)
      ]

      @available_columns << EasyQueryColumn.new(:tags, :preload => [:tags], :caption => :label_easy_tags, :group => group)

      @available_columns.concat(UserCustomField.visible.sorted.collect { |cf| EasyQueryCustomFieldColumn.new(cf) })
      @available_columns_added = true
    end
    @available_columns
  end

  def searchable_columns
    ["#{Principal.table_name}.login", "#{Principal.table_name}.lastname", "#{Principal.table_name}.firstname", "(SELECT address FROM #{EmailAddress.table_name} WHERE user_id=#{Principal.table_name}.id AND is_default = #{self.class.connection.quoted_true} LIMIT 1)"]
  end

  def user_statuses
    user_count_by_status = entity_scope.group('status').count(:all).to_hash
    [
        ["#{l(:status_active)} (#{user_count_by_status[1].to_i})", '1'],
        ["#{l(:status_registered)} (#{user_count_by_status[2].to_i})", '2'],
        ["#{l(:status_locked)} (#{user_count_by_status[3].to_i})", '3']
    ]
  end

  def entity
    User
  end

  def self.chart_support?
    true
  end

  def self.report_support?
    false
  end

  def entity_easy_query_path(options = {})
    users_path(options)
  end

  def get_custom_sql_for_field(field, operator, value)
    case field
    when /^cf_(\d+)$/
      # custom field
      db_table             = CustomValue.table_name
      db_field             = 'value'
      cached_sql_for_field = sql_for_field(field, operator, value, db_table, db_field, true)
      sql                  = "#{User.table_name}.id IN (SELECT #{User.table_name}.id FROM #{User.table_name} LEFT OUTER JOIN #{db_table} ON #{db_table}.customized_type='Principal' AND #{db_table}.customized_id=#{User.table_name}.id AND #{db_table}.custom_field_id=#{$1} "
      sql << 'WHERE ' unless cached_sql_for_field.blank?
      sql << cached_sql_for_field + ')'
      sql
    when 'groups'
      db_table     = 'groups_users'
      db_field     = 'group_id'
      db_in_clause = operator == '!' ? 'NOT IN' : 'IN'
      sql          = "#{User.table_name}.id #{db_in_clause} (SELECT #{User.table_name}.id FROM #{User.table_name} LEFT OUTER JOIN #{db_table} ON #{db_table}.user_id=#{User.table_name}.id WHERE "
      sql << sql_for_field(field, '=', value, db_table, db_field, true) + ')'
      sql
    when 'roles'
      db_not = ['!*', '!'].include?(operator) ? 'NOT ' : ''
      scope  = Role.joins(members: :project).where("#{Member.table_name}.user_id = #{User.table_name}.id").where(projects: { status: [Project::STATUS_ACTIVE, Project::STATUS_PLANNED] }).where.not(projects: { easy_is_easy_template: true })
      scope  = scope.where("#{Member.table_name}.project_id = #{project.id}") if project
      scope  = scope.where(sql_for_field(field, '=', value, Role.table_name, 'id')) if ['!', '='].include?(operator)
      "#{db_not}EXISTS (#{scope.to_sql})"
    when 'easy_user_type'
      sql_for_field(field, operator, value, User.table_name, 'easy_user_type_id')
    when 'mail'
      db_table = EmailAddress.table_name
      db_field = 'address'
      sql_for_field(field, operator, value, db_table, db_field, true)
    else
      ''
    end
  end

  def default_sort_criteria
    @default_sort_criteria ||= super.presence || User.name_formatter[:order]
  end

  def sql_for_user_id_field(field, operator, value)
    if value.size == 1
      # Accepts a comma separated list of ids
      value = value.first.to_s.scan(/\d+/)
    end

    sql_for_field(field, operator, value, entity_table_name, 'id')
  end

end
