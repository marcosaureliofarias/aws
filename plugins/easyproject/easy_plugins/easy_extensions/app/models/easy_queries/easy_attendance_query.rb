class EasyAttendanceQuery < EasyQuery

  def self.permission_view_entities
    :view_easy_attendances
  end

  def entity_easy_query_path(options)
    easy_attendances_path(options)
  end

  def entity_context_menu_path(options = {})
    context_menus_easy_attendances_path(options)
  end

  def query_after_initialize
    super
    self.export_formats[:ics]  = { :caption => 'iCal', :url => { :protocol => 'http', :key => User.current.api_key, :only_path => false }, :title => l(:title_other_formats_links_ics_outlook) }
    self.export_formats[:atom] = { url: { key: User.current.rss_key } }
    self.additional_statement  = "#{EasyAttendance.table_name}.user_id = #{User.current.id}" unless User.current.allowed_to_globally?(:view_easy_attendance_other_users)
  end

  def initialize_available_filters
    on_filter_group(default_group_label) do
      add_available_filter 'arrival', { type: :date_period, time_column: true, order: 1 }
      add_available_filter 'departure', { type: :date_period, time_column: true, order: 2 }
      add_available_filter 'easy_attendance_activity_id', { type: :list, order: 3, values: proc { EasyAttendanceActivity.sorted.collect { |i| [i.name, i.id.to_s] } } }
      add_available_filter 'approval_status', { type: :list, order: 4, values: l(:approval_statuses, scope: :easy_attendance).map { |key, value| [value, key] } }
      add_principal_autocomplete_filter 'approved_by_id', { order: 5 }
      add_available_filter 'hours', { type: :float, order: 6 }
      add_available_filter 'approved_at', { type: :date_period, time_column: true, order: 20 }

      if User.current.allowed_to_globally?(:view_easy_attendance_other_users)
        add_principal_autocomplete_filter 'user_id', { order: 7, source_options: { internal_non_system: true } }
        add_available_filter 'group_id', { type: :list, order: 15, values: proc { Group.active.visible.non_system_flag.sorted.collect { |i| [i.name, i.id.to_s] } } }
      end

      if User.current.allowed_to?(:view_easy_attendances_extra_info, nil, global: true)
        add_available_filter 'arrival_user_ip', { type: :string, order: 9 }
        add_available_filter 'departure_user_ip', { type: :string, order: 10 }
      end

      add_available_filter 'easy_external_id', { type: :string, order: 23 }
    end
  end

  def available_columns
    unless @available_columns_added
      group              = default_group_label
      @available_columns = [
          EasyQueryDateColumn.new(:arrival, :sortable => "#{EasyAttendance.table_name}.arrival", :group => group),
          EasyQueryDateColumn.new(:departure, :sortable => "#{EasyAttendance.table_name}.departure", :group => group),
          EasyQueryColumn.new(:spent_time, :caption => :label_easy_attendance_spent_time, :sumable => :both, :sumable_sql => self.sql_time_diff("#{EasyAttendance.table_name}.arrival", "#{EasyAttendance.table_name}.departure"), :group => group),
          EasyQueryColumn.new(:working_time, :caption => :label_working_time, :group => group),
          EasyQueryColumn.new(:easy_attendance_activity, :groupable => true, :sortable => "#{EasyAttendanceActivity.table_name}.name", :group => group),
          EasyQueryColumn.new(:description, :group => group, :inline => false),
          EasyQueryColumn.new(:approval_status, :group => group),
          EasyQueryColumn.new(:approved_by, :groupable => "#{EasyAttendance.table_name}.approved_by_id", :sortable => lambda { User.fields_for_order_statement('approved_by_users') }, :preload => [:approved_by], :group => group),
          EasyQueryDateColumn.new(:approved_at, :group => group)
      ]

      @available_columns << EasyQueryColumn.new(:hours, :caption => :field_hours, :sortable => "#{EasyAttendance.table_name}.hours", :group => group)

      if User.current.allowed_to?(:view_easy_attendances_extra_info, nil, :global => true)
        @available_columns << EasyQueryColumn.new(:arrival_user_ip, :sortable => "#{self.entity.table_name}.arrival_user_ip", :group => group)
        @available_columns << EasyQueryColumn.new(:departure_user_ip, :sortable => "#{self.entity.table_name}.departure_user_ip", :group => group)
      end

      @available_columns << EasyQueryDateColumn.new(:created_at, :sortable => "#{EasyAttendance.table_name}.created_at", :group => group)
      @available_columns << EasyQueryDateColumn.new(:updated_at, :sortable => "#{EasyAttendance.table_name}.updated_at", :group => group)
      @available_columns << EasyQueryColumn.new(:easy_external_id, :caption => :field_easy_external, :sortable => "#{EasyAttendance.table_name}.easy_external_id", :group => group)

      group = l('label_user_plural')
      @available_columns << EasyQueryColumn.new(:user, :groupable => "#{EasyAttendance.table_name}.user_id", :sortable => lambda { User.fields_for_order_statement }, :group => group)

      @available_columns_added = true
    end
    @available_columns
  end

  def entity
    EasyAttendance
  end

  def self.chart_support?
    true
  end

  def calendar_support?
    true
  end

  def default_find_include
    [:easy_attendance_activity, :user]
  end

  def extended_period_options
    {
        :extended_options => [:to_today, :next_week, :tomorrow, :next_7_days, :next_30_days, :next_90_days, :next_month, :next_year]
    }
  end

  def columns_with_me
    super + ['approved_by_id']
  end

  protected

  def statement_skip_fields
    ['group_id']
  end

  def add_statement_sql_before_filters
    my_fields = statement_skip_fields & filters.keys

    unless my_fields.blank?
      values = values_for('group_id').join(',')
      if values.present?
        sql = "#{EasyAttendance.table_name}.user_id IN (SELECT u.id FROM #{User.table_name} u INNER JOIN groups_users gu ON u.id = gu.user_id WHERE gu.group_id #{operator_for('group_id') == '=' ? 'IN' : 'NOT IN'} (#{values}))"

        return sql
      end
    end
  end

  def add_additional_order_statement_joins(order_options)
    joins = []
    if order_options
      if order_options.include?('approved_by')
        joins << "LEFT OUTER JOIN #{User.table_name} approved_by_users ON approved_by_users.id = #{self.entity.table_name}.approved_by_id"
      end
    end
    joins
  end

end
