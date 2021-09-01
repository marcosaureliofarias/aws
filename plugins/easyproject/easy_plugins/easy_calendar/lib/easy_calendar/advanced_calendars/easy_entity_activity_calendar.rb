module EasyCalendar
  module AdvancedCalendars
    class EasyEntityActivityCalendar < EasyAdvancedCalendar
      #include  EasyIconsHelper

      def self.label
        :label_sales_activities
      end

      def self.permissions
        :view_easy_crms
      end

      def events(start_date, end_date)
        ecrc_events = EasyEntityActivity.arel_table

        EasyEntityActivity.includes(:easy_entity_activity_attendees).preload(:category, :entity).where(is_finished: false, easy_entity_activity_attendees: {entity_id: User.current.id, entity_type: 'Principal'}).where(ecrc_events[:start_time].not_eq(nil).and(ecrc_events[:start_time].lteq(end_date).and(ecrc_events[:start_time].gteq(start_date)))).map do |easy_entity_activity|
          {
            :id => "easy_entity_activity-#{easy_entity_activity.id}",
            :event_type => 'easy_entity_activity_start_time',
            :title => "#{easy_entity_activity.category} - #{easy_entity_activity.entity}",
            :start => User.current.user_time_in_zone(easy_entity_activity.start_time).iso8601,
            :end => User.current.user_time_in_zone(easy_entity_activity.start_time + 15.minutes).iso8601,
            :all_day => easy_entity_activity.all_day,
            :color => '#f96d56',
            :border_color => '#f96d56',
            :editable => false,
            :url => @controller.polymorphic_url(easy_entity_activity.entity, only_path: true)
            #:className => easy_entity_activity.category.easy_icon || ''
          }
        end
      end

    end
  end
end
EasyCalendar::AdvancedCalendar.register(EasyCalendar::AdvancedCalendars::EasyEntityActivityCalendar)
