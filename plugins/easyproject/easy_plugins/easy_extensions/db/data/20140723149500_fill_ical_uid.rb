class FillIcalUid < EasyExtensions::EasyDataMigration
  require 'icalendar'

  def up
    EasyUserTimeCalendarHoliday.find_each(:batch_size => 50) do |h|
      h.update_column(:ical_uid, Icalendar::Event.new.uid.to_s)
    end
  end

  def down
  end

end
