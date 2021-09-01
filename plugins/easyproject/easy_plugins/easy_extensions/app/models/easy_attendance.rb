class EasyAttendance < ActiveRecord::Base
  include Redmine::SafeAttributes

  RANGE_FORENOON  = 1
  RANGE_AFTERNOON = 2
  RANGE_FULL_DAY  = 3
  DEFAULT_RANGE   = RANGE_FULL_DAY

  APPROVAL_WAITING  = 1
  APPROVAL_APPROVED = 2
  APPROVAL_REJECTED = 3
  CANCEL_WAITING    = 4
  CANCEL_APPROVED   = 5
  CANCEL_REJECTED   = 6
  ROUND_MIN_TO      = 15

  belongs_to :easy_attendance_activity
  belongs_to :user, :touch => true
  belongs_to :approved_by, :class_name => 'User', :foreign_key => 'approved_by_id'
  belongs_to :edited_by, :class_name => 'User', :foreign_key => 'edited_by_id'
  belongs_to :time_entry, dependent: :destroy

  validates :easy_attendance_activity, :presence => { :message => Proc.new { I18n.t(:activity_has_no_default_value) } }
  validates :user, :arrival, :presence => true
  validate :easy_attendance_validations

  attr_accessor :new_arrival, :current_user_ip, :non_work_start_time, :factorized_attendances, :warnings, :confirmation, :limit_exceeded
  attr_reader :attendance_date

  attr_accessor :save_factorized_attendances
  alias :save_factorized_attendances? :save_factorized_attendances

  alias :activity :easy_attendance_activity
  delegate :system_activity?, to: :easy_attendance_activity
  delegate :at_work?, to: :easy_attendance_activity

  acts_as_event :title    => Proc.new { |o| "#{o.user} - #{o.easy_attendance_activity}: #{format_time(o.arrival, false)}" + (o.departure ? " - #{format_time(o.departure, false)}" : '') },
                :url      => Proc.new { |o| { :controller => 'easy_attendances', :action => 'edit', :id => o.id } },
                :author   => Proc.new { |o| o.user },
                :datetime => :arrival

  attr_reader :current_journal
  delegate :notes, :notes=, :private_notes, :private_notes=, :to => :current_journal, :allow_nil => true
  acts_as_easy_journalized format_detail_time_columns:       ['arrival', 'departure', 'approved_at'],
                           format_detail_reflection_columns: ['easy_attendance_activity_id', 'approved_by_id'],
                           format_detail_boolean_columns:    ['locked', 'easy_is_repeating'],
                           non_journalized_columns:          ['range', 'arrival_latitude', 'arrival_longitude', 'departure_latitude', 'departure_longitude',
                                                              'previous_approval_status', 'edited_by_id', 'edited_when', 'time_entry_id', 'hours']

  acts_as_activity_provider({ :author_key => :user_id, :timestamp => :arrival })

  html_fragment :description, :scrub => :strip

  scope :visible, lambda { |*args|
    user = args.shift || User.current
    user.allowed_to_globally?(:view_easy_attendance_other_users) ? all : where(user: user)
  }
  scope :approval_required, lambda {
    joins(:easy_attendance_activity).
        where(
            approval_status:            [EasyAttendance::APPROVAL_WAITING, EasyAttendance::CANCEL_WAITING],
            easy_attendance_activities: { approval_required: true }
        ).order(:arrival)
  }
  scope :non_working, lambda { where(EasyAttendanceActivity.arel_table[:at_work].eq(false)).joins(:easy_attendance_activity) }
  scope :reportable, lambda { joins(:easy_attendance_activity).where(EasyAttendanceActivity.arel_table[:approval_required].eq(false).or(EasyAttendance.arel_table[:approval_status].in([APPROVAL_APPROVED, CANCEL_WAITING, CANCEL_REJECTED]))) }
  scope :between, lambda { |date_from, date_to| where(["#{EasyAttendance.table_name}.arrival BETWEEN ? AND ? AND #{EasyAttendance.table_name}.departure BETWEEN ? AND ?", date_from.beginning_of_day, date_to.end_of_day, date_from.beginning_of_day, date_to.end_of_day]) } do
    def sum_spent_time(user_working_time_calendar = nil, return_value_in_hours = false)
      default_working_hours = user_working_time_calendar.default_working_hours if user_working_time_calendar
      default_working_hours ||= 8.0

      inject(0.0) do |memo, att|
        hours = att.spent_time || 0.0

        memo += round_hours_for_day(hours, default_working_hours, default_working_hours / 2, return_value_in_hours)
      end
    end

    def get_spent_time(default_working_hours, half_working_hours, return_value_in_hours = false)
      h = {}
      each do |att|
        h[att.arrival.to_date] ||= 0.0
        h[att.arrival.to_date] += round_hours_for_day(att.spent_time || 0.0, default_working_hours, half_working_hours, return_value_in_hours)
      end
      h
    end
  end

  before_validation :assign_default_activity
  before_save :set_user_ip
  before_save :set_timezone
  before_save :faktorize_attendances
  before_save :ensure_approval_status
  before_save :compute_hours
  after_save :ensure_time_entry
  after_save :create_journal

  after_commit -> { GetAttendanceGeocodeJob.perform_later(self.id) }, on: [:create, :update], if: -> { arrival_coordinates.present? || departure_coordinates.present? }

  safe_attributes 'arrival', 'departure', 'easy_attendance_activity_id', 'range', 'description', 'attendance_date', 'previous_approval_status', 'confirmation'
  safe_attributes 'user_id', :if => Proc.new { |c| User.current.allowed_to_globally?(:edit_easy_attendances, {}) }
  safe_attributes 'approval_status', :if => Proc.new { |c| c.can_approve? || c.can_request_cancel? }
  safe_attributes 'easy_external_id'

  def initialize(*data)
    @warnings = []
    super
  end

  def self.enabled?
    EasyExtensions::EasyProjectSettings.easy_attendance_enabled == true
  end

  def self.css_icon
    'icon icon-time'
  end

  def self.round_hours_for_day(hours, default_working_hours = 8.0, half_working_hours = 4.0, return_value_in_hours = false)
    if hours <= 0.0
      return 0.0
    else
      if hours <= half_working_hours
        if return_value_in_hours
          return half_working_hours
        else
          return 0.5
        end
      else
        if return_value_in_hours
          return default_working_hours
        else
          return 1.0
        end
      end
    end
  end

  def self.new_or_last_attendance(user = nil)
    return nil if !EasyAttendance.enabled?

    user ||= User.current

    easy_attendance      = user.get_easy_attendance_last_arrival || self.new
    easy_attendance.user ||= user

    if easy_attendance.new_record?
      easy_attendance.new_arrival = true
      easy_attendance.arrival     = user.user_time_in_zone
    else
      easy_attendance.new_arrival = false
      easy_attendance.departure   = user.user_time_in_zone
    end

    return easy_attendance
  end

  def self.create_arrival(user, user_ip, options = {})
    return nil if !EasyAttendance.enabled?

    user ||= User.current

    return nil unless user.logged?

    update_activity_on_office(user, user_ip)

    if (last_date = user.pref.last_easy_attendance_arrival_date)
      return nil unless (user.today - last_date).to_i >= 1
    end

    return nil unless User.current.allowed_to_globally?(:use_easy_attendances)

    if !user.current_attendance.nil? || (!options[:ignore_last_today_attendance_to_now] && !user.last_today_attendance_to_now.nil?) || !user.is_work_time?(user.user_time_in_zone)
      update_last_arrival_date_and_user_ip(user, user_ip)
      return nil
    end

    activity = EasyAttendanceActivity.for_ip(user_ip)

    return nil if activity.nil?

    easy_attendance                          = user.easy_attendances.build(:current_user_ip => user_ip, :new_arrival => true)
    easy_attendance.arrival                  = user.user_time_in_zone
    easy_attendance.easy_attendance_activity = activity
    easy_attendance.save

    update_last_arrival_date_and_user_ip(user, user_ip)

    EasyAttendanceUserArrivalNotify.where(:user_id => user.id).each do |e|
      e.send_notify!
    end

    easy_attendance
  end

  def self.update_last_arrival_date_and_user_ip(user, user_ip)
    pref                                   = user.pref
    pref.last_easy_attendance_arrival_date = user.today
    pref.last_easy_attendance_user_ip      = user_ip
    pref.save
  end

  def self.update_activity_on_office(user, user_ip)
    ip_array = office_ip_array
    pref     = user.pref

    if ip_array.any? && pref.last_easy_attendance_user_ip != user_ip && ip_array.include?(IPAddr.new(user_ip)) && User.current.allowed_to_globally?(:use_easy_attendances) && (current_attendance = user.current_attendance) && (activity = EasyAttendanceActivity.for_ip(user_ip))

      if current_attendance.at_work?
        current_attendance.easy_attendance_activity = activity
        current_attendance.save
      end
      update_last_arrival_date_and_user_ip(user, user_ip)
    end
  end

  def self.office_ip_array
    begin
      return EasyAttendance.office_ip_range || []
    rescue IPAddr::InvalidAddressError
      return []
    end
  end

  def self.create_departure(easy_attendance, user_ip, options = {})
    return nil if !EasyAttendance.enabled? || easy_attendance.nil?

    easy_attendance.departure         = Time.now
    easy_attendance.departure_user_ip = user_ip

    if easy_attendance.save(:validate => !options[:force])
      yesterday = easy_attendance.arrival.localtime - 1.day

      if at = easy_attendance.user.easy_attendances.where(:easy_attendance_activity_id => easy_attendance.easy_attendance_activity_id, :departure => nil, :arrival => yesterday.beginning_of_day..yesterday.end_of_day).last
        at.update_columns(:departure => yesterday.end_of_day, :departure_user_ip => user_ip)
        return at
      else
        return easy_attendance
      end
    else
      return nil
    end
  end

  def self.create_arrival_or_departure(user, user_ip, options = {})
    user ||= User.current

    return nil if !user.logged?

    if (easy_attendance = user.current_attendance) && easy_attendance.departure.nil?
      create_departure(easy_attendance, user_ip, options)
    else
      create_arrival(user, user_ip, options)
    end
  end

  def self.office_ip_range
    if self.enabled?
      plugin_settings = Setting.plugin_easy_attendances
      ip_strs         = plugin_settings && Array(plugin_settings['office_ip_range'])
      if ip_strs.present?
        return ip_strs.collect { |ip_str| next if ip_str.blank?; IPAddr.new(ip_str) }.compact
      end
    end
  end

  def self.deliver_pending_attendances(approval_stash)
    map_user_notes = {}
    approval_stash.each do |attendance|
      map_user_notes[attendance.approval_mail] ||= []
      map_user_notes[attendance.approval_mail] << attendance
    end
    map_user_notes.each do |email, easy_attendances|
      EasyMailer.easy_attendance_approval_send_mail_pending(email, easy_attendances).deliver
    end
  end

  def self.deliver_approval_response(approval_stash, notes)
    map_user_notes  = {}
    map_admin_notes = {}
    approval_stash.each do |attendance|
      map_user_notes[attendance.user.mail]                      ||= []
      map_admin_notes[attendance.easy_attendance_activity.mail] ||= []
      map_user_notes[attendance.user.mail] << attendance
      map_admin_notes[attendance.easy_attendance_activity.mail] << attendance
    end
    map_user_notes.each do |email, stash|
      EasyMailer.easy_attendance_send_mail_approval_result(email, stash, notes).deliver
    end
    map_admin_notes.each do |email, stash|
      EasyMailer.easy_attendance_send_mail_approval_result_admin(email, stash, notes, User.current).deliver
    end
  end

  def self.deliver_delete_attendances(approval_stash)
    return if not EasyAttendanceActivity.where(:approval_required => true).exists?

    map_user_notes = {}
    approval_stash.each do |attendance|
      next if attendance.approval_mail.blank?
      map_user_notes[attendance.approval_mail] ||= []
      map_user_notes[attendance.approval_mail] << attendance if attendance.easy_attendance_activity.approval_required?
    end
    map_user_notes.each do |email, easy_attendances|
      EasyMailer.easy_attendance_send_mail_delete_attendances(email, easy_attendances).deliver
    end
  end

  def self.approve_attendances(ids, approve, notes)
    approved             = approve.to_i == 1 unless !!approve == approve
    approved_attendances = []
    invalid_attendances  = []
    easy_attendances     = EasyAttendance.includes(:easy_attendance_activity)
                               .where(
                                   id:                         ids,
                                   approval_status:            [EasyAttendance::APPROVAL_WAITING, EasyAttendance::CANCEL_WAITING],
                                   easy_attendance_activities: { approval_required: true }
                               ).order(:arrival)
    EasyAttendance.transaction do
      easy_attendances.each do |attendance|
        next unless attendance.can_approve?
        attendance.init_journal(User.current, notes)
        attendance.approved_by = User.current
        attendance.approved_at = Time.now

        if attendance.approval_waiting?
          approval_status = approved ? EasyAttendance::APPROVAL_APPROVED : EasyAttendance::APPROVAL_REJECTED
        elsif attendance.cancel_waiting?
          approval_status = approved ? EasyAttendance::CANCEL_APPROVED : EasyAttendance::CANCEL_REJECTED
        end

        if approval_status == EasyAttendance::CANCEL_REJECTED
          attendance.approval_status, attendance.previous_approval_status = attendance.previous_approval_status, attendance.approval_status
        else
          attendance.previous_approval_status, attendance.approval_status = attendance.approval_status, approval_status
        end
        if attendance.save
          approved_attendances << attendance
        else
          invalid_attendances << attendance
          approved_attendances = []
          raise ActiveRecord::Rollback
        end
      end
    end
    if !approved_attendances.empty?
      EasyAttendance.deliver_approval_response(approved_attendances, notes)
    end
    { :saved => approved_attendances, :unsaved => invalid_attendances }
  end

  def self.delete_easy_attendances(easy_attendances)
    easy_attendances = easy_attendances.to_a.select { |easy_attendance| easy_attendance.can_delete? }
    EasyAttendance.deliver_delete_attendances(easy_attendances)
    easy_attendances.each(&:destroy)
  end

  def self.check_limit_exceeded(easy_attendances)
    sum_working_days = Hash.new(0)
    limit_exceeded = false
    difference = {}
    easy_attendances.each do |attendance|
      next if !attendance.easy_attendance_activity || attendance.easy_attendance_activity.at_work?
      user = attendance.user
      arrival_date   = user.user_time_in_zone(attendance.arrival).to_date
      departure_date = user.user_time_in_zone(attendance.departure).to_date

      current_working_days = user.current_working_time_calendar.working_days(arrival_date, departure_date)
      current_working_days /= 2.0 if !(attendance.range == RANGE_FULL_DAY)
      diff_key = "#{attendance.easy_attendance_activity.id}_#{user.id}_#{arrival_date.year}"
      difference[diff_key] ||= attendance.easy_attendance_activity.user_vacation_limit_difference_in_days(user, arrival_date.year)
      next unless difference[diff_key]
      sum_working_days[diff_key] += current_working_days
      if difference[diff_key] < sum_working_days[diff_key]
        attendance.limit_exceeded = true
        limit_exceeded = true
      end
    end
    limit_exceeded
  end

  def cancel_request
    return false unless self.can_request_cancel?

    self.previous_approval_status = self.approval_status
    self.approval_status          = self.direct_cancel? ? CANCEL_APPROVED : CANCEL_WAITING
    self.save
  end

  def direct_cancel?
    approval_waiting? || can_approve?
  end

  def approved?
    approval_status == APPROVAL_APPROVED
  end

  def approval_waiting?
    approval_status == APPROVAL_WAITING
  end

  def cancel_waiting?
    approval_status == CANCEL_WAITING
  end

  def project
    self.time_entry && self.time_entry.project
  end

  def arrival=(value)
    time = build_datetime(value, :morning)
    time = round_time(time) if EasySetting.value(:round_easy_attendance_to_quarters)

    super(time)
  end

  def departure=(value)
    time = build_datetime(value, :evening)
    time = round_time(time) if EasySetting.value(:round_easy_attendance_to_quarters)

    super(time)
  end

  def non_work_start_time=(value)
    @non_work_start_time = build_datetime(value, nil) if value.present?
  end

  def arrival?
    !self.new_arrival.nil?
  end

  def departure?
    !self.arrival?
  end

  def approval_mail
    easy_attendance_activity.mail
  end

  def morning(time)
    user = self.user || User.current
    wc   = user.current_working_time_calendar
    args = [time.year, time.month, time.day, wc.time_from.hour, wc.time_from.min]
    user.user_civil_time_in_zone(*args)
  end

  def evening(time)
    user = self.user || User.current
    wc   = user.current_working_time_calendar
    args = [time.year, time.month, time.day, wc.time_to.hour, wc.time_to.min]
    user.user_civil_time_in_zone(*args)
  end

  def start_date(user = nil)
    user ||= self.user
    if user && user.time_zone
      return user.time_to_date(self.arrival)
    elsif ActiveRecord::Base.default_timezone == :local
      return self.arrival.localtime.to_date
    else
      self.arrival.to_date
    end
  end

  def due_date(user = nil)
    user ||= self.user
    if self.departure
      if user && user.time_zone
        return user.time_to_date(self.departure)
      elsif ActiveRecord::Base.default_timezone == :local
        return self.departure.localtime.to_date
      else
        self.departure.to_date
      end
    end
  end

  def css_classes
    s = 'easy-attendance'
    s << " #{self.easy_attendance_activity.color_schema}"

    return s
  end

  def spent_time
    if self.departure && self.arrival
      (self.departure - self.arrival) / 1.hour
    else
      0.0
    end
  end

  def spent_time_on(day)
    if self.departure && self.arrival
      day_in_zone = User.current.user_time_in_zone(day)
      dep         = if day != User.current.user_time_in_zone(self.departure).to_date
                      [day_in_zone.end_of_day + 1.second, self.departure].min
                    else
                      self.departure
                    end
      arr         = if day != User.current.user_time_in_zone(self.arrival).to_date
                      [day_in_zone.beginning_of_day, self.arrival].max
                    else
                      self.arrival
                    end
      (dep - arr) / 1.hour
    else
      0.0
    end
  end

  def working_time(shifted = false)
    if self.arrival && self.user && (uwtc = self.user.current_working_time_calendar)
      day = self.user.user_time_in_zone(self.arrival).to_date
      uwtc.working_hours(shifted ? uwtc.shift_working_day(1, day) : day)
    end
  end

  def after_create_send_mail
    return if self.approval_mail.blank? || self.arrival.nil? || self.departure.nil?

    easy_attendances = [self]
    easy_attendances.concat(@factorized_attendances) if @factorized_attendances
    if self.easy_attendance_activity.approval_required?
      EasyMailer.easy_attendance_approval_send_mail_pending(self.approval_mail, easy_attendances).deliver
    else
      mail = self.easy_attendance_activity.mail
      EasyMailer.easy_attendance_added(mail, easy_attendances).deliver unless mail.blank?
    end
  end

  def after_update_send_mail
    return if self.approval_mail.blank? || self.arrival.nil? || self.departure.nil?

    easy_attendances = [self]
    easy_attendances.concat(@factorized_attendances) if @factorized_attendances
    if self.easy_attendance_activity.approval_required?
      EasyMailer.easy_attendance_approval_send_mail_pending(self.approval_mail, easy_attendances).deliver
    else
      mail = self.easy_attendance_activity.mail
      EasyMailer.easy_attendance_updated(mail, easy_attendances).deliver unless mail.blank?
    end
  end

  def after_cancel_send_mail
    return if self.approval_mail.blank?

    easy_attendances = [self]
    easy_attendances.concat(@factorized_attendances) if @factorized_attendances
    EasyMailer.easy_attendance_approval_send_mail_pending(self.approval_mail, easy_attendances).deliver
  end

  def can_edit?(user = nil)
    user ||= User.current
    return ((self.user == user && user.allowed_to_globally?(:use_easy_attendances)) || user.allowed_to_globally?(:edit_easy_attendances)) &&
        (can_approve?(user) || !(easy_attendance_activity && easy_attendance_activity.approval_required? && approved?))
  end

  def can_approve?(user = nil)
    user ||= User.current
    return user.allowed_to_globally?(:edit_easy_attendance_approval, {})
  end

  def can_request_cancel?(user = nil)
    user ||= User.current
    (approved? || approval_waiting?) && (User.current.admin? || (self.user == user && user.allowed_to_globally?(:cancel_own_easy_attendances, {}))) && easy_attendance_activity.present? && easy_attendance_activity.approval_required?
  end

  def can_delete?(user = nil)
    user ||= User.current

    return (self.user == user && user.allowed_to_globally?(:delete_own_easy_attendances, {})) || user.allowed_to_globally?(:delete_easy_attendances, {})
  end

  def need_approve?(user = nil)
    user ||= User.current
    easy_attendance_activity&.approval_required? &&
        can_approve?(user) &&
        [EasyAttendance::APPROVAL_WAITING, EasyAttendance::CANCEL_WAITING].include?(approval_status)
  end


  def attendance_date=(value)
    @attendance_date = begin
      value.to_date;
    rescue;
      User.current.today
    end
  end

  def attendance_date
    return @attendance_date if @attendance_date
    if self.arrival
      u = (self.user || User.current)
      (u.time_zone ? u.time_to_date(self.arrival) : self.arrival.localtime.to_date)
    end
  end

  def attendance_status
    return '-' if self.approval_status.nil?

    l(self.approval_status.to_s, :scope => [:easy_attendance, :approval_statuses])
  end

  def visible_custom_field_values(user = nil)
    []
  end

  def custom_field_values(user = nil)
    []
  end

  def attachments
    []
  end

  # for_time: morning | evening
  def build_datetime(value, for_time)
    if value.is_a?(Hash) || value.is_a?(ActionController::Parameters)
      # {date: yyyy-mm-dd, time: "00:11" | time: {hour: 00, minute: 55}}
      date = begin
        value[:date].to_date;
      rescue;
        self.attendance_date
      end
      date ||= (self.arrival || User.current.today)
      if value[:time].is_a?(Hash)
        time = [value[:time][:hour], value[:time][:minute]]
      elsif value[:time].present?
        str_time = value[:time]

        # valid inputs: 09:30, 9:30, 0930, 930, 9,30, 9.30, 9-30
        # invalid inputs: 24:00, 09:60
        if (m = str_time.match(/^([0-1]?[0-9]|2[0-3])([:\-,\.])?([0-5][0-9])$/))
          time = [m[1], m[3]]
        end
      end

      if time.nil? && for_time
        # without time use working time calendar beginning/end of working day
        self.send(for_time, date)
      elsif time.is_a?(Array)
        (self.user || User.current).user_civil_time_in_zone(date.year, date.month, date.day, time[0], time[1])
      end
    elsif value.is_a?(Date) && for_time
      # if value is Date ensure beginning/end of working day
      self.send(for_time, value)
    elsif for_time && /^\d{4}-\d{2}-\d{2}$/.match?(value.to_s)
      # if value is string in supported format ensure beginning/end of working day
      # for API
      self.send(for_time, value.to_date)
    else
      value
    end
  end

  def round_time(value)
    self.class.round_time(value)
  end

  def self.round_time(value)
    return value unless EasyAttendance.enabled?

    round_to = Setting.plugin_easy_attendances['settings_attendance_round'] || ROUND_MIN_TO
    if value.is_a?(String)
      value = value.to_time rescue nil
    end
    if value.is_a?(Time)
      return [value.round_min_to(round_to.to_i), value.end_of_day].min
    end
  end

  def assign_default_activity
    self.easy_attendance_activity ||= EasyAttendanceActivity.default
  end

  def set_default_range
    if easy_attendance_activity && !easy_attendance_activity.specify_by_time?
      self.range ||= EasyAttendance::DEFAULT_RANGE
    else
      self.range = nil
    end
  end

  def easy_attendance_validations
    if self.departure && self.arrival && self.user && self.easy_attendance_activity

      self.errors.add(:departure, l(:departure_is_same_as_arrival, :scope => [:easy_attendance])) if self.arrival == self.departure
      arel = EasyAttendance.arel_table

      scope = user.easy_attendances.where.not(approval_status: [APPROVAL_REJECTED, CANCEL_APPROVED]).where.not(departure: nil)
      scope = scope.where.not(id: id) if id

      where_condition = Arel::Nodes::False.new

      arrival_in_zone   = self.user.user_time_in_zone(self.arrival)
      departure_in_zone = self.user.user_time_in_zone(self.departure)
      # attendance trought midnight
      if arrival > departure || (arrival_in_zone.to_date != departure_in_zone.to_date && (self.departure - self.arrival) < 1.day)
        where_condition    = where_condition.or(arel[:arrival].gteq(arrival_in_zone).and(arel[:departure].lteq(arrival_in_zone.end_of_day)))
        departure_next_day = departure
        departure_next_day += 1.day if arrival_in_zone.to_date == self.user.user_time_in_zone(departure_next_day).to_date
        next_day_arrival   = self.user.user_time_in_zone(departure_next_day).beginning_of_day
        where_condition    = where_condition.or(arel[:arrival].gteq(next_day_arrival).and(arel[:departure].lteq(departure_next_day)))

        self.errors.add(:base, l(:arrival_already_taken, :scope => [:easy_attendance])) if scope.where(where_condition).exists?
        # repeating and normal
      else
        (arrival_in_zone.to_datetime..departure_in_zone.to_datetime).step(1.day).each do |day|
          day_arrival     = self.user.user_civil_time_in_zone(day.year, day.month, day.day, arrival_in_zone.hour, arrival_in_zone.min)
          day_departure   = self.user.user_civil_time_in_zone(day.year, day.month, day.day, departure_in_zone.hour, departure_in_zone.min)
          where_condition = where_condition.or(arel[:arrival].lt(day_departure).and(arel[:departure].gt(day_arrival)))
        end
        self.errors.add(:departure, l(:departure_is_less_than_arrival, :scope => [:easy_attendance])) if departure < arrival
      end

      self.errors.add(:base, l(:arrival_already_taken, :scope => [:easy_attendance])) if scope.where(where_condition).exists?

    end
  end

  def days_of_vacations_in_date(arrival_date)
    user_vacation = EasyAttendance.where("user_id = ? AND easy_attendance_activity_id = ? AND arrival BETWEEN ? AND ?", self.user.id, self.easy_attendance_activity.id, arrival_date.beginning_of_day, arrival_date.end_of_day).limit(1)
    return 0 if user_vacation[0].nil?

    (user_vacation[0].range == RANGE_FULL_DAY) ? 1 : 0.5
  end

  def easy_attendance_vacation_limit_valid?(subtract_waiting=false)
    return true if !self.easy_attendance_activity || self.easy_attendance_activity.at_work?
    arrival_date   = self.user.user_time_in_zone(self.arrival).to_date
    departure_date = self.user.user_time_in_zone(self.departure).to_date

    current_working_days = self.user.current_working_time_calendar.working_days(arrival_date, departure_date)
    current_working_days /= 2.0 if !(self.range == RANGE_FULL_DAY)
    difference = self.easy_attendance_activity.user_vacation_limit_difference_in_days(self.user, arrival_date.year)
    return true if difference.nil?

    difference -= self.easy_attendance_activity.user_waiting_vacation_in_days(self.user, arrival_date.year) if subtract_waiting
    difference += days_of_vacations_in_date(arrival_date) if subtract_waiting
    return difference >= current_working_days
  end

  # method can be used for validation without save
  def faktorize_attendances
    return if user.nil? || activity.nil? || arrival.nil? || departure.nil?
    if save_factorized_attendances.nil?
      self.save_factorized_attendances = true
    end
    @factorized_attendances ||= []
    # If attendance is palnned for longer that 1 day
    # creates attendance record for each day
    if (self.departure - self.arrival) > 1.day
      original_departure = self.departure
      # find first working day if arrival is freeday
      while !self.user.current_working_time_calendar.working_day?(self.user.user_time_in_zone(self.arrival).to_date)
        self.arrival += 1.day
      end
      # set current entity departure to arrival day
      local_arrival   = self.user.user_time_in_zone(self.arrival)
      local_departure = self.user.user_time_in_zone(self.departure)
      self.departure  = self.user.user_civil_time_in_zone(local_arrival.year, local_arrival.month, local_arrival.day, local_departure.hour, local_departure.min)

      attributes = { easy_attendance_activity: self.easy_attendance_activity, user: self.user,
                     arrival_user_ip: self.arrival_user_ip, departure_user_ip: self.departure_user_ip, range: self.range, description: self.description }
      self.approval_status = set_approval_status

      Redmine::Hook.call_hook(:easy_attendance_faktorie_attendances_before_create, { easy_attendance: self, attributes: attributes })

      # create next entities
      (self.user.user_time_in_zone(self.arrival) + 1.day).to_date.upto(self.user.user_time_in_zone(original_departure).to_date) do |day|
        next unless self.user.current_working_time_calendar.working_day?(day)
        local_arrival          = self.user.user_time_in_zone(self.arrival)

        working_hours = self.user.current_working_time_calendar.working_hours(day) if self.range.present?
        if self.range == RANGE_FULL_DAY
          local_departure = self.user.user_time_in_zone(local_arrival + working_hours.hours)
        elsif [RANGE_FORENOON, RANGE_AFTERNOON].include? self.range
          local_departure = self.user.user_time_in_zone(local_arrival + (working_hours / 2.0).hours)
        else
          local_departure = self.user.user_time_in_zone(self.departure)
        end

        attributes[:arrival]   = self.user.user_civil_time_in_zone(day.year, day.month, day.day, local_arrival.hour, local_arrival.min)
        attributes[:departure] = self.user.user_civil_time_in_zone(day.year, day.month, day.day, local_departure.hour, local_departure.min)

        attendance = EasyAttendance.new(attributes)
        if attendance.valid?
          @factorized_attendances << attendance.tap(&:save) if save_factorized_attendances?
        else
          attendance.errors.full_messages.each do |msg|
            self.errors.add(:base, msg)
          end
          raise ActiveRecord::Rollback if save_factorized_attendances?
        end
      end
    elsif arrival > departure
      errors.add :departure, l('easy_attendance.departure_is_less_than_arrival')
      throw(:abort) if save_factorized_attendances?
    elsif (self.user.user_time_in_zone(self.arrival).to_date != self.user.user_time_in_zone(self.departure).to_date)
      # If attendance arrival is not same date as departure
      # but is not logner that 1 day
      # it must be planning over midnight
      next_day = self.dup
      # self close at midnight
      self.send(:write_attribute, :departure, self.user.user_time_in_zone(self.arrival).end_of_day)
      # create new record from midnight to departure next day
      next_day.departure += 1.day if self.user.user_time_in_zone(self.arrival).to_date == self.user.user_time_in_zone(next_day.departure).to_date
      next_day.arrival   = self.user.user_time_in_zone(next_day.departure).beginning_of_day
      if next_day.departure != next_day.arrival && next_day.valid?
        next_day.save if save_factorized_attendances?
      else
        next_day.errors.full_messages.each do |msg|
          self.errors.add(:base, msg)
        end
        raise ActiveRecord::Rollback if save_factorized_attendances?
      end
    elsif !self.approval_status
      set_approval_status
    end
  end

  def attendances_created_from_range
    @factorized_attendances
  end

  def set_approval_status
    self.approval_status = reset_approval? ? APPROVAL_WAITING : APPROVAL_APPROVED
  end

  def reset_approval?
    self.easy_attendance_activity.approval_required? && (arrival_changed? || departure_changed? || user_id_changed? || easy_attendance_activity_id_changed? )
  end

  def ensure_time_entry
    return if self.new_record?
    te = self.time_entry
    # if is mapping enabled and approval is not required OR approval status is approved
    if self.easy_attendance_activity.project_mapping? && (!self.easy_attendance_activity.approval_required? || self.approval_status == APPROVAL_APPROVED)
      if self.easy_attendance_activity.mapped_project && self.easy_attendance_activity.mapped_time_entry_activity && self.arrival && self.departure
        te                 ||= self.build_time_entry
        te.project         = self.easy_attendance_activity.mapped_project
        te.activity        = self.easy_attendance_activity.mapped_time_entry_activity
        te.user            = self.user
        te.easy_range_from = self.arrival
        te.easy_range_to   = self.departure
        te.hours           = (self.departure - self.arrival) / 1.hour
        te.comments        = self.description

        # Settings:
        # user1 has TZ +2
        # user2 has TZ +13
        #
        # Action:
        # user1 add vacations for user1 and user2 on 22.5. (9:00 - 17:00)
        #
        # Database:
        # user1   | 22.5. 07:00 - 15:00 UTC |
        # user2   | 21.5  20:00 - 04:00 UTC |
        #
        # Task:
        # Date on spent_time should be write according user who create an attendance
        #
        te.spent_on = user.user_time_in_zone(arrival).to_date

        unless te.save
          self.errors.add(:time_entry, te.errors.full_messages.join(', '))
          raise ActiveRecord::Rollback
        end
        self.update_column(:time_entry_id, te.id) if te.id != self.time_entry_id
      end
    elsif te
      # te.class.skip_callback(:destroy, :after, :destroy_easy_attendance)
      te.skip_destroy_easy_attendance = true
      te.destroy
    end
  end

  def ensure_approval_status
    return unless reset_approval?

    set_approval_status unless approval_status_changed? && approval_status.in?([APPROVAL_REJECTED, APPROVAL_APPROVED, CANCEL_WAITING, CANCEL_APPROVED, CANCEL_REJECTED])
  end

  def delete_time_entry_on_rejected
    self.time_entry.destroy if self.time_entry
  end

  def set_user_ip
    self.arrival_user_ip   = self.current_user_ip if !self.current_user_ip.blank? && !self.arrival.nil? && self.arrival_user_ip.blank?
    self.departure_user_ip = self.current_user_ip if !self.current_user_ip.blank? && !self.departure.nil? && self.departure_user_ip.blank?
  end

  def arrival_coordinates
    [arrival_latitude, arrival_longitude].reject(&:blank?).join(', ')
  end

  def departure_coordinates
    [departure_latitude, departure_longitude].reject(&:blank?).join(', ')
  end

  def arrival_time_in_user_time_zone
    arrival && user.user_time_in_zone(arrival)
  end

  def departure_time_in_user_time_zone
    departure && user.user_time_in_zone(departure)
  end

  def activity_was
    @activity_was ||= EasyAttendanceActivity.find_by(id: easy_attendance_activity_id_was)
  end

  def ensure_easy_attendance_non_work_activity
    return unless range && easy_attendance_activity && user && !easy_attendance_activity.specify_by_time?

    uwtc = user.current_working_time_calendar
    return unless (ta = validate_attendance_attribute(:arrival))
    return unless (td = validate_attendance_attribute(:departure))
    ta, td = user.user_time_in_zone(ta), user.user_time_in_zone(td)

    if td > ta
      working_days_between = uwtc.working_days(ta.to_date, td.to_date)
    else
      working_days_between = uwtc.working_days(td.to_date, ta.to_date)
    end

    if working_days_between == 0
      # You cannot create an attendence on non-working day
      # However, there is an exception if the attendance is just for one day
      # In that case the system assumed user know what he/she is doing
      if ta.to_date == td.to_date
        ignore_working_hours = true
      else
        return errors.add(:base, l(:error_not_a_working_day, scope: :easy_attendance))
      end
    end

    if ignore_working_hours
      working_hours = lambda { |d| uwtc.default_working_hours }
    else
      ta, td = shift_working_day(ta, uwtc), shift_working_day(td, uwtc, true)
      return if ta.nil? || td.nil?

      working_hours = lambda { |d| uwtc.working_hours(d.to_date) }
    end

    ta             = user.user_civil_time_in_zone(ta.year, ta.month, ta.day, uwtc.time_from.hour, uwtc.time_from.min)
    self.arrival   = ta
    self.departure = user.user_civil_time_in_zone(td.year, td.month, td.day, uwtc.time_to.hour, uwtc.time_to.min)

    case range
    when EasyAttendance::RANGE_FULL_DAY
      na = ta + working_hours.call(ta).hours
    when EasyAttendance::RANGE_FORENOON, EasyAttendance::RANGE_AFTERNOON
      na = if non_work_start_time
             self.arrival = user.user_time_in_zone(non_work_start_time)
           elsif range == EasyAttendance::RANGE_AFTERNOON
             self.arrival = ta + (working_hours.call(ta) / 2.0).hours
           else
             ta
           end
      na += (working_hours.call(na) / 2.0).hours
    else
      raise 'Invalid EasyAttendance RANGE !!!'
    end

    self.departure = user.user_civil_time_in_zone(td.year, td.month, td.day, na.hour, na.min)
  end

  def ensure_faktorized_attendances
    self.save_factorized_attendances = false
    faktorize_attendances
    self.save_factorized_attendances = nil
  end

  def validate_attendance_attribute(attr)
    i = send(attr)
    i.nil? ? (errors.add(attr, :blank); nil) : i
  end

  def shift_working_day(time, uwtc, reverse = false, max_shift = 66)
    max_shift.times do
      if uwtc.working_day?(time.to_date)
        return time
      else
        reverse ? time -= 1.day : time += 1.day
      end
    end
    errors.add(:base, l(:error_working_days))
    nil
  end

  private

  def check_attendance_limits
    # vacation limit validation
    unless self.easy_attendance_activity.nil? || easy_attendance_vacation_limit_valid?
      self.errors.add(:base, l(:vacation_limit_exceed, scope: [:easy_attendance], activity: self.easy_attendance_activity.name, days: self.easy_attendance_activity.user_vacation_limit_difference_in_days(self.user, self.user.user_time_in_zone(self.arrival).to_date.year)))
    end
  end

  def set_timezone
    if arrival_changed? || departure_changed?
      self.time_zone = user.time_zone&.formatted_offset
    end
  end

  def compute_hours
    return if self.departure.blank? || self.arrival.blank?
    return if self.new_record? && self.hours != 0.0
    return if self.persisted? && self.easy_external_id.present?

    self.hours = (self.departure - self.arrival) / 3600
  end

end
