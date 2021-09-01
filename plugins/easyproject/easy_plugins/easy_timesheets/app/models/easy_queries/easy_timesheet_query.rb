class EasyTimesheetQuery < EasyQuery

  def initialize_available_filters
    on_filter_group(default_group_label) do
      add_principal_autocomplete_filter 'user_id', { order: 1, includes: [:user] }
      add_available_filter 'start_date', { type: :date_period, order: 2 }
      add_available_filter 'end_date', { type: :date_period, order: 3, label: :label_easy_timesheet_end_date }
      add_available_filter 'created_at', { type: :date_period, order: 4, time_column: true }
      add_available_filter 'updated_at', { type: :date_period, order: 5, time_column: true }
      add_available_filter 'locked', { type: :boolean, label: :label_easy_timesheet_approved, order: 6 }
      add_principal_autocomplete_filter 'locked_by_id', { label: :label_easy_timesheet_approved_by, order: 7 }
      add_principal_autocomplete_filter 'unlocked_by_id', { label: :label_easy_timesheet_rejected_by, order: 8 }
      add_available_filter 'locked_at', { type: :date_period, label: :label_easy_timesheet_locked_at, time_column: true, order: 9 }
    end
  end

  def available_columns
    unless @available_columns_added
      group = default_group_label
      group_user = l('label_user_plural')
      @available_columns = [
        EasyQueryColumn.new(:title, :group => group),
        EasyQueryColumn.new(:user, :sortable => lambda{User.fields_for_order_statement('users')}, :groupable => "#{EasyTimesheet.table_name}.user_id", :includes => [:user], :group => group_user),
        EasyQueryColumn.new(:total, :caption => :label_total, :group => group),
        EasyQueryColumn.new(:start_date, :sortable => "#{EasyTimesheet.table_name}.start_date", :group => group),
        EasyQueryColumn.new(:end_date, :sortable => "#{EasyTimesheet.table_name}.end_date", :caption => :label_easy_timesheet_end_date, :group => group),
        EasyQueryColumn.new(:locked_by, :caption => :label_easy_timesheet_approved_by, :groupable => true, :sortable => lambda { User.fields_for_order_statement('locked_by_users') }, :preload => [:locked_by], :group => group),
        EasyQueryColumn.new(:unlocked_by, :caption => :label_easy_timesheet_rejected_by, :groupable => true, :sortable => lambda { User.fields_for_order_statement('unlocked_by_users') }, :preload => [:unlocked_by], :group => group),
        EasyQueryColumn.new(:locked_at, :caption => :label_easy_timesheet_locked_at, :sortable => "#{EasyTimesheet.table_name}.locked_at", :group => group),
        EasyQueryColumn.new(:lock_description, :caption => :label_easy_timesheet_lock_description, :group => group)
      ]
      @available_columns_added = true
    end
    @available_columns
  end

  def entity
    EasyTimesheet
  end

  def entity_easy_query_path(options = {})
    easy_timesheets_path(options)
  end

  def entity_scope
    @entity_scope ||= entity.visible
  end

  def default_list_columns
    d = super
    d = %w{ title user_id start_date end_date } if d.empty?
    d
  end

  def add_additional_order_statement_joins(order_options)
    joins = []
    if order_options
      if order_options.include?('locked_by')
        joins << "LEFT OUTER JOIN #{User.table_name} locked_by_users ON locked_by_users.id = #{self.entity.table_name}.locked_by_id"
      end
      if order_options.include?('unlocked_by')
        joins << "LEFT OUTER JOIN #{User.table_name} unlocked_by_users ON unlocked_by_users.id = #{self.entity.table_name}.unlocked_by_id"
      end
    end
    joins
  end

  def self.report_support?
    false
  end

end
