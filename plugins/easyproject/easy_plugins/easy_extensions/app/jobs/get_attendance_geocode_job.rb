require 'geocoder'

class GetAttendanceGeocodeJob < EasyActiveJob
  queue_as :default

  def perform(easy_attendance_id)
    easy_attendance = EasyAttendance.find(easy_attendance_id)

    begin
      arrival_coord   = Geocoder.coordinates(easy_attendance.arrival_user_ip) if easy_attendance.arrival_user_ip.present?
      departure_coord = Geocoder.coordinates(easy_attendance.departure_user_ip) if easy_attendance.departure_user_ip.present?

      easy_attendance.update_columns(arrival_latitude: arrival_coord[0], arrival_longitude: arrival_coord[1]) if arrival_coord
      easy_attendance.update_columns(departure_latitude: departure_coord[0], departure_longitude: departure_coord[1]) if arrival_coord
    rescue Geocoder::Error, Timeout::Error
      raise ::EasyActiveJob::RetryException
    end
  end

end
