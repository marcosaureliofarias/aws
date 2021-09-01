class EasyRoom < ActiveRecord::Base
  include Redmine::SafeAttributes

  safe_attributes 'name', 'capacity'

  has_many :easy_meetings

  validates :name, presence: true
  validates :capacity, numericality: { allow_nil: true, only_integer: true, greater_than: 0 }

  def to_s
    name
  end

  def name_with_capacity
    if capacity?
      "#{name} (#{l :label_place, count: capacity})"
    else
      name
    end
  end

  def available_for_date?(start_time, end_time, current_meeting_id = nil)
    meetings = EasyMeeting.arel_table
    conflict = easy_meetings
                 .where(
                   meetings[:id].not_eq(current_meeting_id).and(
                     meetings[:start_time].lt(end_time).and(
                       meetings[:end_time].gt(start_time).or(
                         meetings[:start_time].gt(start_time).and(
                           meetings[:end_time].lt(end_time)
                         ).or(
                           meetings[:start_time].eq(start_time).and(
                             meetings[:end_time].eq(end_time)
                           )
                         )
                       )
                     )
                   )
                 ).first
    !conflict
  end
end
