class EasyAttendanceComputeHours < EasyExtensions::EasyDataMigration
  def up
    EasyAttendance.where.not(arrival: nil).where.not(departure: nil).find_each(batch_size: 50) do |easy_attendance|
      hours = (easy_attendance.departure - easy_attendance.arrival) / 3600 if easy_attendance.departure && easy_attendance.arrival && easy_attendance.hours == 0.0
      easy_attendance.update_columns(hours: hours) unless hours.nil?
    end
  end

  def down
  end

end
