module EasyCalendar
  module AdvancedCalendars
    class EasyMeetingCalendar < EasyAdvancedCalendar
      def self.label; :label_meetings; end
      def self.new_record_path; :new_easy_meeting_path; end
      def self.create_record_path; :easy_meetings_path; end

      def self.has_project_events?
        true
      end

      def self.has_room_events?
        true
      end

      def events(start_date, end_date)
        meetings = EasyMeeting.arel_table
        user = User.current

        events = EasyMeeting.includes([:easy_invitations, :easy_room]).where(:easy_invitations => {:user_id => user.id}).
          where(:easy_invitations => {:accepted => [true, nil]}).
          where(meetings[:start_time].lt(end_date)).
          where(meetings[:end_time].gt(start_date)).distinct.to_a

        events.map! {|meeting|
          {
            :id => "easy_meeting-#{meeting.id}",
            :event_type => (meeting.author_id == user.id) ? 'meeting' : 'meeting_invitation',
            :url => @controller.easy_meeting_path(meeting),
            :parent_url => (meeting.easy_repeat_parent_id) ? @controller.easy_meeting_path(meeting.easy_repeat_parent_id) : '',
            :location => meeting.easy_room.try(:name),
            :title => meeting.name,
            :start => user.user_time_in_zone(meeting.start_time).iso8601,
            :end => user.user_time_in_zone(meeting.end_time).iso8601,
            :all_day => meeting.all_day,
            :color => '#daddf6',
            :border_color => '#c3d0e5',
            :editable => meeting.editable?(user),
            :accepted => meeting.accepted_by?(user),
            :declined => meeting.declined_by?(user),
            :big_recurring_children => meeting.big_recurring_children?
          }}

        events
      end

      def project_events(start_date, end_date, project)
        meetings = EasyMeeting.arel_table
        user = User.current
        events = EasyMeeting.
          where(meetings[:start_time].lt(end_date)).
          where(meetings[:end_time].gt(start_date)).
          where(meetings[:project_id].eq(project.id)).to_a

        events.map! {|meeting|
          {
            :id => "easy_project_meeting-#{meeting.id}",
            :event_type => (meeting.author_id == user.id) ? 'meeting' : (meeting.user_invited?(user) ? 'meeting_invitation' : 'meeting_detail'),
            :url => @controller.easy_meeting_path(meeting),
            :title => meeting.name,
            :start => user.user_time_in_zone(meeting.start_time).iso8601,
            :end => user.user_time_in_zone(meeting.end_time).iso8601,
            :all_day => meeting.all_day,
            :color => '#daddf6',
            :border_color => '#c3d0e5',
            :editable => (!meeting.big_recurring_children? && (user.admin? || meeting.author_id == user.id)),
            :big_recurring_children => meeting.big_recurring_children?
          }}

        events
      end

      def room_events(start_date, end_date, room)
        meetings = EasyMeeting.arel_table
        user = User.current
        events = EasyMeeting.
          where(meetings[:start_time].lt(end_date)).
          where(meetings[:end_time].gt(start_date)).
          where(meetings[:easy_room_id].eq(room.id)).to_a

        events.map! {|meeting|
          {
            :id => "easy_room_meeting-#{meeting.id}",
            :event_type => 'room_meeting',
            :title => meeting.name,
            :start => user.user_time_in_zone(meeting.start_time).iso8601,
            :end => user.user_time_in_zone(meeting.end_time).iso8601,
            :all_day => meeting.all_day,
            :color => '#daddf6',
            :border_color => '#c3d0e5',
            :editable => false
          }}

        events
      end

    end

    class EasyMeetingAuthorCalendar < EasyAdvancedCalendar
      def self.label; :label_meetings_created_by_me; end

      def events(start_date, end_date)
        meetings = EasyMeeting.arel_table
        user = User.current

        events = EasyMeeting.includes([:easy_invitations, :easy_room]).where(:author_id => user.id).
          where(meetings[:start_time].lt(end_date)).
          where(meetings[:end_time].gt(start_date)).uniq.to_a

        events.map! {|meeting|
          {
            :id => "easy_meeting-#{meeting.id}",
            :event_type => 'meeting',
            :url => @controller.easy_meeting_path(meeting),
            :parent_url => (meeting.easy_repeat_parent_id) ? @controller.easy_meeting_path(meeting.easy_repeat_parent_id) : '',
            :location => meeting.easy_room.try(:name),
            :title => meeting.name,
            :start => user.user_time_in_zone(meeting.start_time).iso8601,
            :end => user.user_time_in_zone(meeting.end_time).iso8601,
            :all_day => meeting.all_day,
            :color => '#daddf6',
            :border_color => '#c3d0e5',
            :editable => !meeting.big_recurring_children?,
            :accepted => meeting.accepted_by?(user),
            :declined => meeting.declined_by?(user),
            :big_recurring_children => meeting.big_recurring_children?
          }}

        events
      end
    end
  end
end
EasyCalendar::AdvancedCalendar.register(EasyCalendar::AdvancedCalendars::EasyMeetingCalendar)
EasyCalendar::AdvancedCalendar.register(EasyCalendar::AdvancedCalendars::EasyMeetingAuthorCalendar)
