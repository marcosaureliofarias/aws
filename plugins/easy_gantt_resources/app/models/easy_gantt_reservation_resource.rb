class EasyGanttReservationResource < ActiveRecord::Base

  belongs_to :reservation, class_name: 'EasyGanttReservation', foreign_key: 'easy_gantt_reservation_id'

  scope :between_dates, lambda { |start_date, end_date|
    where('date BETWEEN ? AND ?', start_date, end_date) if start_date && end_date
  }

end
