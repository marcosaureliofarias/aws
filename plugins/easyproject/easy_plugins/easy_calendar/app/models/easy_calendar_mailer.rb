require 'ostruct'

class EasyCalendarMailer < EasyBlockMailer
  include Redmine::I18n
  include EasyCalendarMailerHelper

  def easy_meeting_invitation(easy_meeting, mail, invitee_mails = [], options = {})
    invitee_mails = [mail] unless invitee_mails.present?

    if (@invited_user = User.find_by_mail(mail))
      set_language_if_valid(@invited_user.language)
      @external = @invited_user.external_client?
    else
      @external = true
    end

    meeting_url = easy_meeting_page_url(easy_meeting: easy_meeting, external: @external)

    ical = Icalendar::Calendar.new
    ical.event do |e|
      e.uid = easy_meeting.uid
      e.url = meeting_url if meeting_url
      e.summary = easy_meeting.name
      e.description = ActionController::Base.helpers.strip_tags(easy_meeting.description)
      e.location = easy_meeting.easy_room.to_s if easy_meeting.easy_room
      e.dtstart = easy_meeting.start_time.utc.iso8601(0).gsub(/[-:]/, '')
      e.dtend = easy_meeting.end_time.utc.iso8601(0).gsub(/[-:]/, '')
      e.organizer = "mailto:#{easy_meeting.author.mail}" if easy_meeting.author.mail.present?
      Array(invitee_mails).each do |mail|
        e.append_attendee "mailto:#{mail}"
      end
    end

    @easy_meeting = easy_meeting

    @user = @invited_user || User.current
    @invitor = User.current.logged? ? User.current : easy_meeting.author

    mixed = mail(to: mail, subject: invitation_subject(@easy_meeting)) do |format|
      format.html
      format.text
      format.ics { render plain: ical.to_ical }
    end
    mixed.content_type 'multipart/mixed'
    mixed.header['content-type'].parameters[:boundary] = mixed.body.boundary

    alt = Mail::Part.new { content_type 'multipart/alternative' }
    mixed.parts.delete_if { |p| alt.add_part p }
    alt.parts[2].content_type 'text/calendar; charset=UTF-8; method=REQUEST'

    mixed.attachments['invitation.ics'] = { content: ical.to_ical, content_type: 'application/ical' }
    mixed.add_part(alt)
    mixed.body.set_sort_order(['multipart/alternative', 'application/ical'])
  end

  def easy_meeting_invitation_accepted(invitation)
    @easy_meeting = invitation.easy_meeting
    @user = invitation.user
    mail to: @easy_meeting.author.mail, subject: l(:title_meeting_invitation_accepted, user: @user)
  end

  def easy_meeting_invitation_declined(invitation)
    @easy_meeting = invitation.easy_meeting
    @user = invitation.user
    mail to: @easy_meeting.author.mail, subject: l(:title_meeting_invitation_declined, user: @user)
  end

  def easy_meeting_room_conflict(easy_meeting, conflict_meetings = [])
    @easy_meeting = easy_meeting
    @conflict_meetings = conflict_meetings.map(&:name).uniq.join(', ')
    mail to: @easy_meeting.author.mail, subject: l(:title_meeting_room_conflict, name: @easy_meeting.name)
  end

  def easy_meeting_removal(user, serialized_meeting_hash)
    meeting = JSON.parse(serialized_meeting_hash, object_class: OpenStruct)

    @user = user
    @start_time = @user.user_time_in_zone(meeting.start_time)
    @end_time = @user.user_time_in_zone(meeting.end_time)
    @name = meeting.name
    @all_day = meeting.all_day

    subject = l(:title_meeting_removed, name: @name)
    mail to: @user.mail, subject: subject
  end
end
