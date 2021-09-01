class CreateDefaultEasyUserWorkingTimeCalendars < EasyExtensions::EasyDataMigration
  def self.up
    calendars_path = File.join(EasyExtensions::EASY_EXTENSIONS_DIR, 'assets', 'easy_calendars')
    calendars      = [
        { name: 'Czech work calendar', file: File.join(calendars_path, 'CzechHolidays.ics') },
        { name: 'German work calendar', file: File.join(calendars_path, 'GermanHolidays.ics') },
        { name: 'French work calendar', file: File.join(calendars_path, 'FrenchHolidays.ics') },
        { name: 'Russian work calendar', file: File.join(calendars_path, 'RussiaHolidays.ics') }
    ]
    calendars.each do |c|
      calendar = EasyUserWorkingTimeCalendar.create :name => c[:name], :default_working_hours => 8.0, :ical_url => c[:file].to_s, :ical_update => true
      calendar.update_column(:ical_url, nil)
    end
  end

  def self.down
  end

end
