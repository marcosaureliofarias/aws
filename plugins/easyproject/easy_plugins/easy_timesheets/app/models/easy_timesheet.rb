class EasyTimesheet < ActiveRecord::Base
  include Redmine::SafeAttributes
  include Redmine::I18n

  belongs_to :user
  belongs_to :locked_by, class_name: 'User'
  belongs_to :unlocked_by, class_name: 'User'

  has_many :time_entries

  attr_accessor :rows
  attribute :period, :string, default: -> { self.enabled_period }

  delegate :cell_css_classes, :day_title, to: :calendar

  scope :visible, lambda { |*args| where(EasyTimesheet.visible_condition(args.shift || User.current, *args)) }
  scope :monthly, -> { where(period: 'month') }
  scope :weekly, -> { where(period: 'week') }

  safe_attributes 'user_id',
    if: lambda { |easy_timesheet, user| user.allowed_to_globally?(:add_timeentries_for_other_users, {}) }

  safe_attributes 'start_date', 'end_date', 'period'

  validates :user_id, :start_date, :end_date, presence: true
  validate :easy_timesheet_validation

  before_save :ensure_end_date
  after_create :ensure_time_entries, if: Proc.new{ |t| t.id.present? }
  after_destroy :release_time_entries

  def self.available_periods
    ['week', 'month']
  end

  def self.enabled_period
    EasySetting.value('easy_timesheets_enabled_timesheet_calendar') || self.default_period
  end

  def self.default_period
    'month'
  end

  def self.wants_comment_inputs?
    true
  end

  def self.weekly_calendar_enabled?
    self.enabled_period == 'week'
  end

  def self.monthly_calendar_enabled?
    self.enabled_period == 'month'
  end

  def previous
    @previous_time_sheet ||= self.class.where(user_id: self.user_id).where(["#{self.class.table_name}.end_date < ?", self.end_date]).order(:end_date).last
    @previous_time_sheet
  end
  alias_method :prev, :previous

  def next
    @next_time_sheet ||= self.class.where(user_id: self.user_id).where(["#{self.class.table_name}.end_date > ?", self.end_date]).order(:end_date).first
    @next_time_sheet
  end

  # This may slow creating TimeEntries
  def self.enable_ensure_time_sheet_for_time_entry?
    true
  end

  def self.visible_condition(user, options={})
    timesheets = EasyTimesheet.arel_table
    scope = timesheets[:period].eq(EasyTimesheet.enabled_period)

    if user.allowed_to_globally_view_all_time_entries?
      scope.to_sql
    elsif user.allowed_to_globally?(:view_personal_statement, {})
      scope.and(timesheets[:user_id].eq(user.id)).to_sql
    else
      '1=0'
    end
  end

  def monthly?
    self.period == 'month'
  end

  def weekly?
    self.period == 'week'
  end

  def over_time_rows
    rows.select { |r| r.over_time }
  end

  def non_over_time_rows
    rows - over_time_rows
  end

  def total_hours
    sum_row.each_cell.map { |cell| cell.sum_hours }.sum
  end

  def over_time?(time_entry)
    cf_over_time = EasySetting.value(:custom_field_overtime_id)
    value = time_entry.custom_value_for(cf_over_time).try(:cast_value)
    if !!value == value
      result = value
    else
      result = value.present? ? true : false
    end
    result
  end

  def available_periods
    self.class.available_periods
  end

  def title
    "#{self.user.to_s} #{format_date(self.start_date)} - #{format_date(self.end_date)}"
  end
  alias_method :to_s, :title

  def self.css_icon
    'icon icon-time-add'
  end

  def visible?(user = nil)
    user ||= User.current
    user.allowed_to_globally?(:view_time_entries, {}) && (user.allowed_to_globally_view_all_time_entries? || self.user_id == user.id)
  end

  def editable?(user = nil)
    return false if new_record?
    user ||= User.current
    !self.locked? && (user.allowed_to_globally?(:edit_time_entries, {}) || (self.user_id == user.id && user.allowed_to_globally?(:edit_own_time_entries, {})))
  end

  def addable?(user = nil)
    return false if new_record?
    user ||= User.current
    !self.locked? && (user.allowed_to_globally?(:log_time, {}) && (user.allowed_to_globally?(:add_timeentries_for_other_users, {}) || self.user_id == user.id))
  end

  def can_lock?(user = nil)
    time_entry = self.time_entries.first || TimeEntry.new(user: self.user)
    time_entry.can_lock?(user) if time_entry
  end

  def can_unlock?(user = nil)
    time_entry = self.time_entries.first || TimeEntry.new(user: self.user)
    time_entry.can_unlock?(user) if time_entry
  end

  def calendar(date=nil)
    date = begin date.try(:to_date); rescue; nil end
    date ||= start_date || (self.user || User.current).today
    @calendar = EasyTimesheets::Calendar.new(date, self.period.to_sym, current_language, (self.user || User.current))
    @calendar
  end

  def each_row(&block)
    @rows ||= create_timesheet_rows
    return @rows if !block_given?
    @rows.each(&block)
  end
  alias_method :rows, :each_row

  def build_new_row
    row = EasyTimesheets::EasyTimesheetRow.new(self, build_empty_cells)
    row.is_new_row = true
    row
  end

  def start_date=(date)
    super(calendar(date).startdt)
  end


  def working_dates
    @working_dates ||= Array(self.start_date..self.end_date)
    @working_dates
  end

  def working_days
    @working_days ||= working_dates.count
    @working_days
  end

  def find_row(row_id)
    self.each_row.detect{|r| r.dom_id == row_id }
  end

  def remove_row(row_id)
    return if @rows.nil?
    row_id = row_id.id if row_id.is_a?(EasyTimesheets::EasyTimesheetRow)

    @rows.delete_if{|r| r.dom_id == row_id }
  end

  def calculate_sum_row(cell=nil)
    @sum_row ||= EasyTimesheets::EasyTimesheetRow.new(self, build_empty_cells)
    if cell
      add_hours_to_sum_row(cell.spent_on, cell.sum_hours)
    elsif @rows
      @rows.each{|row| row.each_cell{|cell| self.calculate_sum_row(cell) }}
    else
      @rows = create_timesheet_rows
    end
    @sum_row
  end

  def add_hours_to_sum_row(spent_on, hours)
    @sum_row ||= EasyTimesheets::EasyTimesheetRow.new(self, build_empty_cells)
    @sum_row.add_value(spent_on, hours)
  end

  def sum_row(force_recalculate=false)
    @sum_row = nil if force_recalculate

    @sum_row || calculate_sum_row
  end

  def time_entry_scope_for_timesheet
    scope = TimeEntry.visible_with_archived.where(user_id: user_id).
      where(spent_on: start_date..end_date).preload(:project, :issue, :activity)
    scope = scope.preload(easy_attendance: :easy_attendance_activity) if Redmine::Plugin.installed?(:easy_attendances)
    scope
  end

  def lock!(lock_description=nil)
    self.locked = true
    self.lock_description = lock_description
    resolve_lock
    if self.save
      self.time_entries.update_all(:easy_locked => true, :easy_locked_by_id => User.current.id, :easy_locked_at => Time.now.localtime)
      return true
    else
      return false
    end
  end

  def unlock!(lock_description=nil)
    self.locked = false
    self.lock_description = lock_description
    resolve_lock
    if self.save
      self.time_entries.update_all(:easy_locked => false, :easy_unlocked_by_id => User.current.id, :easy_unlocked_at => Time.now.localtime)
      return true
    else
      return false
    end
  end

  def validate_lock
    errors.add(:base, :is_locked) if self.locked?
  end

  def total
    sum_row.sum_hours
  end

  def copy_rows_from(another_easy_timesheet)
    origin_rows = self.rows
    @rows = build_new_rows_from(another_easy_timesheet)
    @rows.concat(origin_rows)
  end

  def build_new_rows_from(another_easy_timesheet)
    another_easy_timesheet.rows.collect do |row|
      r = build_new_row
      r.attributes = { project: row.project, activity: row.activity, issue: row.issue, read_only: true }
      r.over_time = row.over_time if EasySetting.value('easy_timesheets_over_time') == '1'
      r
    end
  end

  def ensure_end_date
    self.end_date = calendar.enddt
  end

  def create_timesheet_rows(scope=nil)
    if new_record?
      scope ||= time_entry_scope_for_timesheet.includes(:project).preload(:custom_values)
    else
      scope ||= time_entry_scope_for_timesheet.where(easy_timesheet_id: self.id).includes(:project).preload(:custom_values)
    end
    rows = []
    scope.reorder("#{Project.table_name}.name ASC").each do |time_entry|
      user_over_time = (monthly? && EasySetting.value('easy_timesheets_over_time') == '1')
      over_time = over_time?(time_entry) if user_over_time
      if (row = rows.detect { |r| r.fit_to_time_entry?(time_entry, user_over_time ? over_time : nil) })
        row.add_time_entry(time_entry)
      else
        row = EasyTimesheets::EasyTimesheetRow.new(self, build_empty_cells)
        row.over_time = over_time if user_over_time
        row.add_time_entry(time_entry)
        rows << row
      end
    end
    rows
  end
  private

  def resolve_lock
    if self.locked_was
      self.unlocked_by = User.current
      self.unlocked_at = Time.now.localtime
    else
      self.locked_by = User.current
      self.locked_at = Time.now.localtime
    end
  end


  def ensure_time_entries
    time_entry_scope_for_timesheet.where(easy_timesheet_id: nil).update_all(easy_timesheet_id: id)
  end

  def release_time_entries
    self.time_entries.update_all(easy_timesheet_id: nil)
  end

  def build_empty_cells
    cells = ActiveSupport::OrderedHash.new

    working_dates.each do |d|
      cells[d.to_s] ||= EasyTimesheets::EasyTimesheetRowCell.new(self, d)
    end

    cells
  end

  def easy_timesheet_validation
    scope = EasyTimesheet.where(user_id: self.user_id).where('start_date <= :ed AND end_date >= :sd OR start_date >= :sd AND end_date <= :ed', sd: self.start_date, ed: self.end_date)
    scope = scope.where.not(id: self.id) unless self.new_record?
    if scope.any?
      self.errors.add(:base, :error_timesheet_already_exists_in_this_week)
    end
  end

end


