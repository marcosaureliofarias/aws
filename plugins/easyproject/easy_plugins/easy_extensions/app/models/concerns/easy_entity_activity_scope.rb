module EasyEntityActivityScope
  extend ActiveSupport::Concern

  included do
    scope :sorted, -> { order(start_time: :desc) }

    scope :active, -> { where(is_finished: false) }

    scope :finished, -> { where(is_finished: true) }

    scope :my_activities, -> (user_id) {
      includes(:easy_entity_activity_attendees).
          where(easy_entity_activity_attendees: { entity_id: user_id, entity_type: 'Principal' })
    }

    scope :user_activities, -> (user_id, start_time, end_time) {
      my_activities(user_id).
          active.
          between(start_time, end_time).
          preload(:category, :entity)
    }

    scope :between, -> (start_time, end_time) {
      if start_time && end_time
        where(in_period(start_time, end_time))
      else
        where('1=1')
      end
    }

  end

  module ClassMethods

    def in_period(start_time, end_time)
      arel_table[:start_time].not_eq(nil).and(
          start_time_condition(start_time, end_time).or(end_time_condition(start_time, end_time))
      )
    end

    def start_time_condition(start_time, end_time)
      start_time_in_period(start_time, end_time)
    end

    def start_time_in_period(start_time, end_time)
      arel_table[:start_time].lteq(end_time).and(arel_table[:start_time].gteq(start_time))
    end

    def end_time_condition(start_time, end_time)
      arel_table[:end_time].eq(nil).or(end_time_in_period(start_time, end_time))
    end

    def end_time_in_period(start_time, end_time)
      arel_table[:end_time].lteq(end_time).and(arel_table[:end_time].gteq(start_time))
    end
  end
end
