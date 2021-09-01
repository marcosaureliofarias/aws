class EasyUserTimeCalendar < ActiveRecord::Base
  include EasyIcalHelper
  include Redmine::SafeAttributes

  default_scope { order("#{self.table_name}.position ASC") }

  serialize :working_week_days

  belongs_to :user, :touch => true
  has_many :holidays, :class_name => 'EasyUserTimeCalendarHoliday', :foreign_key => 'calendar_id', :dependent => :destroy
  has_many :exceptions, :class_name => 'EasyUserTimeCalendarException', :foreign_key => 'calendar_id', :dependent => :destroy

  acts_as_tree :dependent => :destroy
  acts_as_positioned :scope => :user_id

  has_many :parent_exceptions, through: :parent, source: :exceptions
  has_many :parent_holidays, through: :parent, source: :holidays

  validates_length_of :name, :in => 1..255, :allow_nil => false
  validates_numericality_of :default_working_hours, :allow_nil => false, :message => :invalid, :greater_than_or_equal_to => 0.0, :less_than_or_equal_to => 24.0
  validates :first_day_of_week, :time_from, :time_to, :presence => true

  before_save :change_default
  before_save :change_default_working_hours
  before_save :parse_icalendar, :if => Proc.new { |p| p.ical_update && p.ical_url.present? }
  after_save :add_holidays_from_ical
  after_initialize :set_default_values
  after_update :propagate_inherited_values

  after_destroy :invalidate_cache
  after_save :invalidate_cache
  after_touch :invalidate_cache

  scope :templates, lambda { where(:user_id => nil, :parent_id => nil) }

  attr_reader :current_date, :startdt, :enddt
  attr_accessor :ical_update

  safe_attributes 'name',
                  'user_id',
                  'parent_id',
                  'default_working_hours',
                  'first_day_of_week',
                  'builtin',
                  'is_default',
                  'position',
                  'time_from',
                  'time_to',
                  'type',
                  'working_week_days',
                  'ical_url',
                  'reorder_to_position'

  def self.find_by_user(user)
    EasyUserTimeCalendar.where(:user_id => user).where.not(:parent_id => nil).first if !user.nil?
  end

  def self.default
    self.find_by(:is_default => true, :user_id => nil, :parent_id => nil)
  end

  def name=(arg)
    # cannot change name of a builtin calendar
    super unless self.builtin?
  end

  def template?
    user_id.nil? && parent_id.nil?
  end

  def cache_key
    if new_record?
      'uwtc/new'
    else
      "uwtc/#{id}-#{updated_at.strftime('%Y%m%d%H%M%S')}"
    end
  end

  def invalidate_cache
    if template?
      User.includes(:working_time_calendar).where(:easy_user_time_calendars => { :id => nil }).each { |u| u.touch }
      descendants.each { |c| c.touch }
    end
  end

  def assign_to_user(user, preserve_calendar_exceptions = false)
    return false unless user.is_a?(User)

    attributes               = self.attributes.dup.except('id', 'user_id', 'parent_id', 'is_default', 'builtin')
    attributes['user_id']    = user.id
    attributes['parent_id']  = self.id
    attributes['is_default'] = false

    old_calendar = self.class.find_by(user: user)
    new_calendar = self.class.new(attributes)

    self.class.transaction do
      if preserve_calendar_exceptions
        new_calendar.exceptions << self.exceptions.collect { |e| e.dup }
      end

      new_calendar.save!
      old_calendar.destroy if old_calendar
    end
    new_calendar
  end

  def reset
    exceptions.clear
    if parent
      exceptions << parent.exceptions.collect { |e| e.dup }
      self.default_working_hours = parent.default_working_hours
      self.time_from             = parent.time_from
      self.time_to               = parent.time_to
      save
    end
    touch
  end

  def initialize_inner_calendar(current_date = nil)
    if current_date.is_a?(String)
      @current_date = begin
        ; current_date.to_date;
      rescue;
      end
    else
      @current_date = current_date
    end
    @current_date ||= Date.today
    @startdt      = Date.civil(@current_date.year, @current_date.month, 1)
    @enddt        = (@startdt >> 1) - 1
    # starts from the first day of the week
    @startdt = @startdt - (@startdt.cwday - self.first_wday) % 7
    # ends on the last day of the week
    @enddt = @enddt + (self.last_wday - @enddt.cwday) % 7
  end

  def first_day_of_week
    self.parent.nil? ? read_attribute(:first_day_of_week) : self.parent.first_day_of_week
  end

  def translated_name
    if self.builtin?
      l("easy_user_working_time_calendar_names.#{self.name.downcase}".to_sym)
    else
      self.name
    end
  end

  def working_time(day)
    if self.working_day?(day)
      if exc = self.exception(day)
        return exc.working_hours
      else
        @attendance_time ||= ((self.time_to - self.time_from).seconds / 1.hour)
        return @attendance_time
      end
    else
      return 0.0
    end
  end

  def sum_working_time(from = nil, to = nil)
    from ||= Date.today
    to   ||= Date.today
    sum  = 0.0
    from.upto(to) { |day| sum += self.working_time(day) }
    sum
  end

  def working_hours(day)
    Rails.cache.fetch("working_hours/#{day}/#{self.cache_key}", :expires_in => 1.day) do
      if exc = self.exception(day)
        exc.working_hours
      elsif self.holiday?(day)
        0.0
      else
        if self.weekend?(day)
          0.0
        else
          self.default_working_hours
        end
      end
    end
  end

  def working_hours_between(day_from = nil, day_to = nil)
    h        = {}
    day_from ||= Date.today
    day_to   ||= Date.today

    self.exception_between(day_from, day_to).each do |e|
      h[e.exception_date] ||= e.working_hours
    end

    day_from.upto(day_to) do |day|
      h[day] ||= 0.0 if self.holiday?(day)
      h[day] ||= 0.0 if self.weekend?(day)
      h[day] ||= self.default_working_hours
    end

    h
  end

  def working_days(from = nil, to = nil)
    from       ||= Date.today
    to         ||= Date.today
    days_count = 0

    from.upto(to) do |day|
      days_count += 1 if self.working_day?(day)
    end
    days_count
  end

  def sum_working_hours(from = nil, to = nil)
    from ||= Date.today
    to   ||= Date.today

    working_hours_between(from, to).values.sum
  end

  def sum_working_hours_ignore_holidays(from = nil, to = nil)
    from ||= Date.today
    to   ||= Date.today
    sum  = 0.0
    from.upto(to) do |day|
      if !self.weekend?(day)
        sum += self.default_working_hours
      end
    end
    sum
  end

  def working_week_days
    working_days = Array(super)

    working_days.delete_if(&:blank?)
    if working_days.empty?
      return self.parent ? self.parent.working_week_days : (1..5).to_a
    end
    working_days.map(&:to_i)
  end

  def weekend?(day)
    !working_week_days.include?(day.cwday)
  end

  def working_day?(day)
    self.working_hours(day) > 0.0
  end

  def holiday(day)
    (self.parent.nil? ? self : self.parent).holidays.detect { |ex| ex.is_repeating? ? (ex.holiday_date.day == day.day && ex.holiday_date.month == day.month) : (ex.holiday_date == day) }
  end

  def holiday?(day)
    !self.holiday(day).nil?
  end

  def exception(day)
    exceptions_between_cache.day(day) ||
        (self.parent.nil? ? self.exceptions : self.exceptions + self.parent.exceptions).detect { |ex| ex.exception_date == day }
  end

  def exception_between(day_from, day_to)
    exceptions_between_cache.with_cache(day_from, day_to, range: true) do |from, to|
      e = self.exceptions.where(["#{EasyUserTimeCalendarException.table_name}.exception_date BETWEEN ? AND ?", from, to])
      e += self.parent.exception_between(from, to) unless self.parent_id.blank?
      e
    end
  end

  def exception?(day)
    !self.exception(day).nil?
  end

  def first_wday
    @first_wday ||= (self.first_day_of_week - 1) % 7 + 1
  end

  def last_wday
    @last_wday ||= (self.first_wday + 5) % 7 + 1
  end

  def prev_start_date
    @current_date - 1.month
  end

  def next_start_date
    @enddt + 1.day
  end

  def month
    @current_date.month
  end

  def year
    @current_date.year
  end

  def css_classes(day)
    s = []
    s << 'today' if Date.today == day
    s << 'weekend' if self.weekend?(day)
    s << 'holiday' if self.holiday?(day)
    s << 'exception' if self.exception?(day)
    s.join(' ')
  end

  def minutes_per_day
    self.default_working_hours * 60
  end

  def minutes_per_week
    self.minutes_per_day * 5
  end

  # shifts given start_date by delta, then moves it to the next(self included) working day
  def shift_working_day(delta, start_date = nil, max_shift = 66)
    start_date ||= Date.today
    end_date   = start_date + delta.days

    if working_day?(end_date) || max_shift <= 0
      end_date
    elsif delta > 0
      shift_working_day(1, end_date, max_shift - 1)
    else
      shift_working_day(-1, end_date, max_shift - 1)
    end
  end

  # shifts given start_date by delta only by working days
  def shift_by_working_days(delta, start_date: nil, max_shift: 66)
    start_date ||= Date.today

    end_date = start_date + delta.days
    # + 1 to not count start_date
    working_days_shift      = working_days(start_date + 1, end_date)
    minimal_remaining_shift = delta - working_days_shift

    while minimal_remaining_shift > 0
      next_start_date         = end_date
      end_date                = shift_working_day(minimal_remaining_shift, next_start_date, max_shift - minimal_remaining_shift)
      working_days_shift      += working_days(next_start_date + 1, end_date)
      minimal_remaining_shift = delta - working_days_shift
    end

    end_date
  end

  private

  def change_default
    if self.is_default? && self.user_id.blank? && self.is_default_changed?
      self.class.where(:user_id => nil, :parent_id => nil).update_all(:is_default => false)
    end
  end

  def set_default_values
    return unless new_record? && self.class.column_names.include?('time_from')
    t              = Time.now
    self.time_from = Time.utc(t.year, t.month, t.day, 9) if self.time_from.nil?
    self.time_to   = Time.utc(t.year, t.month, t.day, 17, 30) if self.time_to.nil?
  end

  def change_default_working_hours
    return unless self.class.column_names.include?('time_from')
    if !self.time_from.blank? && !self.time_to.blank? && self.default_working_hours.blank?
      self.default_working_hours = (self.time_to - self.time_from) / 3600
    end
  end

  def propagate_inherited_values
    return unless self.class.column_names.include?('time_from')
    if (saved_change_to_default_working_hours? || saved_change_to_time_from? || saved_change_to_time_to?) && children.any?
      children.where(:default_working_hours => default_working_hours_before_last_save).update_all(:default_working_hours => default_working_hours)
      children.where(:time_from => time_from_before_last_save).update_all(:time_from => time_from)
      children.where(:time_to => time_to_before_last_save).update_all(:time_to => time_to)
    end
  end

  def parse_icalendar
    begin
      @icalendar = load_icalendar(self.ical_url)
    rescue StandardError, Timeout::Error => e
      self.errors[:base] << "#{I18n.t(:notice_ical_import_failed)}: #{e.message}"
      return false
    end
    if @icalendar.nil?
      self.errors[:base] << I18n.t(:notice_ical_import_failed)
      return false
    end
    @icalendar
  end

  def add_holidays_from_ical
    if @icalendar
      ical_uids = self.holidays.pluck(:ical_uid)
      self.holidays << holidays_from_icalendar(@icalendar).reject { |h| ical_uids.include?(h.ical_uid) }
    end
  end

  def exceptions_between_cache
    @exceptions_between_cache ||= CalendarCache.new(:exceptions, day_method: :exception_date)
  end

  # calendar cache for between ranges
  class CalendarCache

    def initialize(cache_for = nil, options = {})
      @cache_for         = cache_for
      @calendar_cache    = Hash.new
      @from              = nil
      @to                = nil
      @options           = options.dup
      @last_range_result = nil
      @last_range        = []
    end

    def with_cache(from, to, options = {}, &block)
      cache(from, to, options, &block)
      if options[:range]
        range(from, to)
      else
        @calendar_cache.select { |day, value| day > from && day < to }
      end
    end

    def cache(from, to, options = {}, &block)
      load = true

      if !(@from && @to)
        @from = from
        @to   = to
      elsif to <= @from
        to    = @from
        @from = from
      elsif from >= @to
        from = @to
        @to  = to
      else
        ofrom = from.dup
        oto   = to.dup
        load  = false
        if ofrom < @from
          from = ofrom
          to   = @from
          @calendar_cache.merge!(load_values(from, to, options, &block))
          @from = ofrom
        end

        if oto > @to
          from = @to
          to   = oto
          @calendar_cache.merge!(load_values(from, to, options, &block))
          @to = oto
        end
      end

      @calendar_cache.merge!(load_values(from, to, options, &block)) if load
    end

    def day(date)
      @calendar_cache[date]
    end

    def range(from, to)
      return @last_range_result if @last_range.first == from && @last_range.second == to
      result = []
      from.upto(to) { |day| result << @calendar_cache[day] if @calendar_cache[day] }
      result
    end

    private

    def load_values(from, to, options = {}, &block)
      values = yield(from, to)
      if options[:range]
        @last_range_result = values
        @last_range        = [from, to]
        values             = values.inject({}) do |memo, value|
          date       = value.send(@options[:day_method])
          memo[date] = value
          memo
        end
      end

      values
    end

  end

end
