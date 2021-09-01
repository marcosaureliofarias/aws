class EasyInvitation < ActiveRecord::Base

  # Alarms in minutes
  DEFAULT_ALARMS = ['05', '30']

  belongs_to :easy_meeting, touch: true
  belongs_to :user

  scope :visible, -> (*args) { joins(:user).merge(User.visible(args.shift || User.current)) }

  attr_accessor :skip_notifications

  before_create :set_alarms
  after_update :notify_meeting_author

  validates :user, :presence => true

  serialize :alarms, Array

  def color_by_status
    case accepted
    when nil
      nil
    when true
      '#008015'
    when false
      '#b32400'
    end
  end

  def class_by_status
    case accepted
    when nil
      nil
    when true
      'positive'
    when false
      'negative'
    end
  end

  def accepted?
    accepted == true
  end

  def declined?
    accepted == false
  end

  private

  def set_alarms
    self.alarms = []

    DEFAULT_ALARMS.each do |min|
      alarm = Icalendar::Alarm.new
      alarm.action  = 'DISPLAY'
      alarm.summary = "#{min.to_i} minutes before"
      alarm.trigger = "-PT#{min}M"

      self.alarms << alarm.to_ical
    end
  end

  def notify_meeting_author
    return if skip_notifications
    return if easy_meeting.big_recurring_children?
    return if !Setting.notified_events.include?('meeting')

    if self.easy_meeting && (self.easy_meeting.author != self.user)
      if accepted?
        EasyCalendarMailer.easy_meeting_invitation_accepted(self).deliver
      elsif declined?
        EasyCalendarMailer.easy_meeting_invitation_declined(self).deliver
      end
    end
  end

end
