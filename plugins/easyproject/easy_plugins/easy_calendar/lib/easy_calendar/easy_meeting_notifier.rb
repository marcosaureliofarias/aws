module EasyCalendar
  class EasyMeetingNotifier

    attr_reader :easy_meeting, :user_mails
    delegate :external_mails, to: :easy_meeting

    def initialize(easy_meeting)
      @easy_meeting = easy_meeting
      @user_mails = get_user_mails
    end

    def self.call(easy_meeting)
      if !Setting.notified_events.include?('meeting')
        return
      end

      service = new(easy_meeting)
      service.notify
      service
    end

    def notify
      notify_users if user_mails.any?
      notify_external_users if external_mails.any?
      easy_meeting.update_column(:emailed, true)
    end

    def notify_users
      user_mails.each do |mail|
        EasyCalendarMailer.easy_meeting_invitation(easy_meeting, mail, user_mails).deliver
      end
    end

    def notify_external_users
      external_mails.each do |mail|
        EasyCalendarMailer.easy_meeting_invitation(easy_meeting, mail, nil).deliver
      end
    end

    private

    def get_user_mails
      active_user_clause = User.arel_table[:status].eq(Principal::STATUS_ACTIVE)

      user_ids = easy_meeting.easy_invitations
                   .joins(:user)
                   .where(active_user_clause)
                   .where.not(user: easy_meeting.author)
                   .pluck(:user_id)

      EmailAddress.where(notify: true, user_id: user_ids).pluck(:address)
    end
  end
end
