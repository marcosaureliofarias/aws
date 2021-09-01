class CreateDefaultEasyUserWorkingTimeCalendar2 < EasyExtensions::EasyDataMigration
  def self.up
    unless EasyUserWorkingTimeCalendar.where(:builtin => true).any?
      EasyUserWorkingTimeCalendar.create(:name => 'Standard', :builtin => true, :is_default => true, :default_working_hours => 8.0, :first_day_of_week => 1)
    end
  end

  def self.down
    EasyUserWorkingTimeCalendar.where(:builtin => true).destroy_all
  end
end