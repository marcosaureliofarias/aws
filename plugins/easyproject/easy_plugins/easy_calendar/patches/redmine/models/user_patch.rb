module EasyCalendar
  module UserPatch

    def self.included(base)
      base.class_eval do
        base.include(InstanceMethods)

        alias_method_chain :available_working_hours, :easy_calendar
        alias_method_chain :available_working_hours_between, :easy_calendar
        alias_method_chain :remove_references_before_destroy, :easy_calendar

        has_many :easy_invitations, :dependent => :destroy
        has_many :easy_meetings, :foreign_key => :author_id
        has_many :invited_to_meetings, :class_name => 'EasyMeeting', :through => :easy_invitations, :source => :easy_meeting
        has_many :easy_icalendars, dependent: :destroy
        accepts_nested_attributes_for :easy_icalendars,
          reject_if: -> (attrs) { attrs['url'].blank? || attrs['name'].blank? },
          allow_destroy: true
        safe_attributes 'easy_icalendars', 'easy_icalendars_attributes'
      end
    end

    module InstanceMethods

      def available_working_hours_with_easy_calendar(day)
        h = available_working_hours_without_easy_calendar(day)

        start_date = day.beginning_of_day
        end_date = day.end_of_day

        events = easy_meetings.between(start_date, end_date).to_a
        events.concat(invited_to_meetings.between(start_date, end_date)
          .where("#{EasyMeeting.table_name}.author_id <> ?", self.id).to_a)

        h -= events.sum(&:duration_hours)
        h = 0.0 if h < 0.0

        h
      end

      def available_working_hours_between_with_easy_calendar(day_from = nil, day_to = nil)
        h = available_working_hours_between_without_easy_calendar(day_from, day_to)

        if association(:easy_meetings).loaded?
          range = day_from..day_to
          events = easy_meetings.select{|m|range.cover?(m.start_time) && range.cover?(m.end_time) }
        else
          events = easy_meetings.between(day_from, day_to).to_a
        end
        events.concat(invited_to_meetings.between(day_from, day_to)
          .where("#{EasyMeeting.table_name}.author_id <> ?", self.id).to_a)

        events.each do |m|
          start_date = m.start_time.to_date
          if h[start_date].present?
            h[start_date] -= m.duration_hours
            h[start_date] = 0.0 if h[start_date] < 0.0
          end
        end

        h
      end

      def remove_references_before_destroy_with_easy_calendar
        remove_references_before_destroy_without_easy_calendar
        substitute = User.anonymous
        EasyMeeting.where(author_id: self.id).update_all(author_id: substitute.id)
        EasyInvitation.where(user_id: self.id).destroy_all
      end

    end

  end
end
EasyExtensions::PatchManager.register_model_patch 'User', 'EasyCalendar::UserPatch'
