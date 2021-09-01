class EasyMeeting < ActiveRecord::Base
  include Redmine::SafeAttributes

  # These enums are defined based on iCalendar property. Do not change this.
  # Priority: CUA iCalendar priority property which have three-level scheme
  # Privacy: its only provide an intention of the owner for the access
  enum priority: ['high', 'normal', 'low']
  enum privacy: ['xpublic', 'xprivate', 'confidential']
  enum email_notifications: ['right_now', 'one_week_before'], _prefix: :emailed

  MAX_BIG_RECURRING_COUNT = 100
  NOTIFY_DAYS = 7 # for email notifications settings :one_week_before

  belongs_to :author, :class_name => 'User', :foreign_key => 'author_id'
  belongs_to :project
  belongs_to :easy_room

  scope :between, lambda { |from, to| where(start_time: from..to, end_time: from..to) }

  has_many :easy_invitations, lambda { order(:accepted => :desc) }, :dependent => :destroy
  has_many :users, :through => :easy_invitations, :after_add => :changed_users, :after_remove => :changed_users

  validates :author, :name, :start_time, :end_time, :presence => true
  validates :name, :place_name, length: { maximum: 255 }
  validates :uid, uniqueness: true
  validate :validate_mails
  validate :validate_room_capacity
  validate :validate_room_conflicts
  validate :validate_user_count
  validate :validate_times
  validate :validate_big_recurring

  validates_inclusion_of :priority, in: EasyMeeting.priorities.keys
  validates_inclusion_of :privacy, in: EasyMeeting.privacies.keys

  attr_accessor :do_not_send_notifications
  attr_accessor :reset_invitations
  attr_accessor :reflect_on_big_recurring_childs

  attribute :emailed, :boolean, default: false
  attribute :email_notifications, :integer, default: EasyMeeting.email_notifications[:one_week_before]

  after_initialize :set_defaults
  before_create :set_uid
  # after_update :reset_invitations
  after_update :reset_invitations_when_change, if: -> { reset_invitations? && saved_change_to_start_time? }
  before_save :save_big_recurring_state

  after_save :notify_invitees, if: -> { need_notification? && required_email_notifications? }
  before_save :update_emailed, if: -> { persisted? && need_notification? }

  after_create :accept_author_invitation
  after_commit :update_big_recurring

  include EasyPatch::Acts::Repeatable
  acts_as_easy_repeatable before_save:               -> (new_meeting, parent_meeting) { parent_meeting.repeat_before_save(new_meeting) },
                          after_save:                -> (new_meeting, parent_meeting) { new_meeting.check_after_save(parent_meeting) },
                          start_col:                 :start_time,
                          end_col:                   :end_time,
                          repeat_parent_id_col:      :easy_repeat_parent_id,
                          delayed_create_supported?: false

  # Big recurring event is created immediately after commit
  scope :easy_to_repeat, -> do
    m_table = EasyMeeting.table_name
    next_start = Date.today + NOTIFY_DAYS.days
    easy_repeating.where("#{m_table}.big_recurring = ?", false).
                   where("#{m_table}.easy_next_start <= ? OR #{m_table}.easy_next_start IS NULL", next_start)
  end

  scope :easy_to_notify, -> do
    meetings = EasyMeeting.arel_table
    start_date = Arel::Nodes::NamedFunction.new 'DATE', [ meetings[:start_time] ]
    where(start_date.lteq(Date.today + NOTIFY_DAYS.days))
      .where(start_date.gteq(Date.today))
      .where(meetings[:emailed].not_eq(true))
  end

  scope :self_and_future, -> (id) { where(id: id).or(EasyMeeting.where(easy_repeat_parent_id: id)) }

  html_fragment :description, :scrub => :strip

  safe_attributes 'name',
                  'all_day',
                  'start_time',
                  'end_time',
                  'easy_room_id',
                  'project_id',
                  'description',
                  'user_ids',
                  'mails',
                  'place_name',
                  'priority',
                  'privacy',
                  'big_recurring',
                  'email_notifications',
                  'reflect_on_big_recurring_childs',
                  'reset_invitations',
                  'uid', if: proc {|e| e.new_record? || e.editable? }

  def visible?(user = User.current)
    privacy != 'confidential' || author_id == user.id || user_invited?(user)
  end

  def visible_details?(user = User.current)
    visible?(user) && (privacy != 'xprivate' ||
                       author_id == user.id ||
                       user.allowed_to_globally?(:view_all_meetings_detail) ||
                       user_invited?(user))
  end

  def set_defaults
    return unless new_record?
    next_hour = Time.now.round_min_to(60)
    self.start_time ||= next_hour
    self.end_time ||= next_hour + 1.hour
    self.author ||= User.current
  end

  def repeat_before_save(new_one)
    new_one.user_ids = user_ids
    new_one.uid = EasyUtils::UUID.generate

    if big_recurring?
      new_one.big_recurring = true
    end
  end

  def check_after_save(orig)
    if (conflict_meetings = find_room_conflict_meetings).present?
      EasyCalendarMailer.easy_meeting_room_conflict(self, conflict_meetings).deliver
    end
  end

  # Method included from `EasyPatch::Acts::Repeatable`. Called after_save.
  # Since new mettings will be created on new Thread this entity must be commited
  # on DB so new callback `update_big_recurring` will be triggered.
  def create_repeated
    if @big_recurring_change_state.nil? || @big_recurring_change_state.empty?
      super
    end
  end

  # Must be on `after_commit` callback
  # Be careful with:
  # - instance variable is also duplicated via `.dup`
  # - this method is also triggered after children is created via big recurring
  def update_big_recurring
    return unless !easy_repeat_parent_id? && (@big_recurring_change_state&.any? || @big_recurring_attrs_changed&.any?)

    EasyCalendar::BigRecurringJob.perform_later(self, @big_recurring_change_state.map(&:to_s), @big_recurring_attrs_changed)
  end

  # easy_is_repeating?
  #   easy_is_repeating_was?
  #     big_recurring?
  #       big_recurring_was?
  #
  # 0 1 0 1 - Delete all
  # 0 1 1 1 - Delete all
  # 1 0 1 0 - Create all
  # 1 0 1 1 - Create all
  # 1 1 0 1 - Delete all, reset counter
  # 1 1 1 0 - Delete all, create all
  # x x x x - Nothing
  def save_big_recurring_state
    # Only parent can change big recurring
    return if big_recurring_children?

    @big_recurring_change_state = []

    # If recurring setting or times changed
    if (big_recurring? && easy_is_repeating? && !easy_repeat_parent_id?) && (easy_repeat_settings_changed? || start_time_changed? || end_time_changed?)
      @big_recurring_change_state << :reset_counter << :delete_all << :create_all
      return
    end

    state = [
      easy_is_repeating,
      easy_is_repeating_was,
      big_recurring,
      big_recurring_was
    ]

    case state
    when [false, true, false, true], [false, true, true, true]
      @big_recurring_change_state << :delete_all

    when [true, false, true, false], [true, false, true, true]
      @big_recurring_change_state << :create_all

    when [true, true, false, true]
      @big_recurring_change_state << :delete_all << :reset_counter

    when [true, true, true, false]
      @big_recurring_change_state << :delete_all << :create_all

    when [true, true, true, true]
      @big_recurring_change_state << :update_all
      @big_recurring_attrs_changed = changed - ['easy_repeat_settings']
      @big_recurring_attrs_changed << 'user_ids' if @users_changed
    end
  end

  # Should be ++big_recurring_child?++
  def big_recurring_children?
    big_recurring? && easy_repeat_parent_id?
  end

  def big_recurring_parent?
    big_recurring? && easy_repeat_parent_id.nil?
  end

  def start_time=(t)
    write_attribute :start_time, parse_date_time_attribute(t)
  end

  def end_time=(t)
    write_attribute :end_time, parse_date_time_attribute(t)
  end

  def duration_hours
    (end_time - start_time) / 1.hour
  end

  def external_mails
    parse_mails(self.mails)
  end

  def user_invited?(user)
    # easy_invitations.where(:user_id => user.id).exists?
    !!invitation_for(user)
  end

  def invitation_for(user)
    @invitation_for ||= {}
    @invitation_for[user.id] ||= easy_invitations.detect{ |i| i.user_id == user.id }
    @invitation_for[user.id]
  end

  def accept!(user = User.current)
    accept_or_decline!(user, true)
  end

  def decline!(user = User.current)
    accept_or_decline!(user, false)
  end

  def accept_or_decline!(user, accepted)
    if reflect_on_big_recurring_childs?
      check_id = easy_repeat_parent_id || id
      meeting_ids = EasyMeeting.self_and_future(check_id).ids
    else
      meeting_ids = [id]
    end

    scope = EasyInvitation.where(easy_meeting_id: meeting_ids)
    scope = scope.where(user_id: user) if user
    scope.update_all(accepted: accepted)
  end

  def accepted_by?(user)
    !!invitation_for(user).try(:accepted?)
  end

  def declined_by?(user)
    !!invitation_for(user).try(:declined?)
  end

  def send_notifications?
    !do_not_send_notifications.to_boolean
  end

  def reflect_on_big_recurring_childs?
    big_recurring? && reflect_on_big_recurring_childs.to_boolean
  end

  def reset_invitations?
    reset_invitations.to_boolean
  end

  def total_user_count
    external_mails.size + user_ids.size
  end

  def user_ids=(user_ids)
    user_ids.reject!(&:blank?)
    user_ids.map!(&:to_i)
    user_ids.uniq!

    groups = Principal.from('groups_users').where(groups_users: { group_id: user_ids }).pluck(:user_id, :group_id)
    groups.each do |user_id, group_id|
      user_ids.delete(group_id)
      user_ids << user_id
    end


    user_ids.uniq!
    super(user_ids)
  end

  def easy_repeate_update_time_cols(time_vector, start_timepoint = nil, options={})
    # without localtime problems with summer/winter time
    self.start_time = self.start_time.localtime + time_vector
    self.end_time = self.end_time.localtime + time_vector
  end

  def set_uid
    self.uid = EasyUtils::UUID.generate if self.uid.blank?
  end

  def etag
    "#{self.id}-#{self.updated_at.to_i}"
  end

  def destroy_all_repeated
    check_id = easy_repeat_parent_id || id
    EasyMeeting.self_and_future(check_id).destroy_all
  end

  def destroy_current_and_following_repeated
    check_id = easy_repeat_parent_id || id
    meetings = EasyMeeting.arel_table
    EasyMeeting.where(meetings[:easy_repeat_parent_id].eq(check_id))
      .where(meetings[:big_recurring].eq(false))
      .where(meetings[:start_time].gt(self.start_time))
      .or(EasyMeeting.where(id: self.id))
      .destroy_all
  end

  def editable?(user = nil)
    user ||= User.current

    !big_recurring_children? && (
      user.admin? || (user.id == author_id) || user.allowed_to_globally?(:edit_meetings)
    )
  end

  def find_room_conflict_meetings
    if easy_room && start_time && end_time
      meetings = EasyMeeting.arel_table
      easy_room.easy_meetings
        .where(
          meetings[:id].not_eq(id).and(
            meetings[:start_time].lt(end_time).and(
              meetings[:end_time].gt(start_time).or(
                meetings[:start_time].gt(start_time).and(
                  meetings[:end_time].lt(end_time)).or(
                    meetings[:start_time].eq(start_time).and(
                      meetings[:end_time].eq(end_time))
                ))
            )
          )
        )
    end
  end

  def validate_room_conflicts
    if easy_room && start_time && end_time
      if (conflict_meetings = find_room_conflict_meetings).present?
        errors.add(:base, l(:error_meeting_room_conflict, conflict: conflict_meetings.map(&:name).join(', ')))
      end
    end
  end

  def send_notification_about_removal(easy_invitations = [])
    accepted_keys = %w{name all_day start_time end_time}
    easy_invitations.each do |easy_invitation|
      EasyCalendarMailer.easy_meeting_removal(easy_invitation.user, attributes.to_json(only: accepted_keys)).deliver_later
    end
  end

  # Do not override users input, return name of room, users input
  #
  #
  # @return [String] location for CalDav
  # @see https://tools.ietf.org/html/rfc5545#section-3.8.1.7
  def location
    loc = [easy_room&.name]
    loc << place_name.presence
    loc.compact.join(", ")
  end

  private

  def validate_mails
    if external_mails.detect{|mail| !/\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i.match?(mail)}
      errors.add(:mails, :invalid_plural)
    end
  end

  def validate_room_capacity
    if easy_room.try(:capacity?)
      if total_user_count > easy_room.capacity
        errors.add(:base, l(:error_room_capacity_breached, user_count: total_user_count, capacity: easy_room.capacity))
      end
    end
  end

  def validate_user_count
    errors.add(:base, l(:error_any_user_in_meeting)) if users.empty?
  end

  def validate_times
    if self.end_time && self.start_time && self.end_time < self.start_time
      errors.add :base, l(:error_meeting_end_must_be_greater_than_start, :end_date => format_time(self.end_time), :start_date => format_time(self.start_time))
    end
  end

  def validate_big_recurring
    return if !easy_is_repeating?
    return if !big_recurring?

    case easy_repeat_settings['endtype']
    when 'count'
      count = easy_repeat_settings['endtype_count_x'].to_i
      if count > MAX_BIG_RECURRING_COUNT
        errors.add(:big_recurring, l(:error_easy_meeting_big_recurring_max_count))
      end
    when 'date'
      # During repeating MAX_BIG_RECURRING_COUNT is taken
    end
  end


  def notify_invitees
    EasyCalendar::EasyMeetingNotifier.call(self)
  end

  def parse_date_time_attribute(t)
    time = if t.is_a?(Hash) && t['date'] && t['time']
      Time.parse("#{t['date']} #{t['time']}")
    elsif t.is_a?(String)
      t.to_datetime
    end
    time ? User.current.user_civil_time_in_zone(time.year, time.month, time.day, time.hour, time.min, time.sec) : t
  rescue ArgumentError
    nil
  end

  def parse_mails(mail_str)
    if mail_str.present?
      mail_str.split(/,\s*/)
    else
      []
    end
  end

  #Stop spaming
  def reset_invitations_when_change
    easy_invitations.where.not(user_id: User.current.id).update_all(accepted: nil)
    reset_invitations = nil
  end

  # auto accept invitation if author inlude himself in meeting
  def accept_author_invitation
    if self.user_ids.include?(self.author_id)
      accept!(self.author)
    end
  end

  def changed_users(_user)
    @users_changed = true
  end

  # inclusive today and today + 7 days
  def upcoming_event?
    (Date.today..Date.today + NOTIFY_DAYS.days).include?(start_time.to_date)
  end

  def required_email_notifications?
    return false if start_time < Time.now - 1.day

    return true if emailed_right_now?

    upcoming_event? if emailed_one_week_before?
  end

  def update_emailed
    self.emailed = false
  end

  def need_notification?
    !big_recurring_children? &&
      send_notifications? &&
        (saved_changes? || @users_changed)
  end

end
