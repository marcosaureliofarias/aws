ActiveSupport.on_load(:easyproject, yield: true) do
  require 'easy_timesheets/internals'
  require 'easy_timesheets/hooks'
  require 'easy_timesheets/calendar'

  require 'easy_timesheets/menus'
  require 'easy_timesheets/proposer'
  require 'easy_timesheets/permissions'
end

RedmineExtensions::Reloader.to_prepare do

  EasyQuery.map do |query|
    query.register 'EasyTimesheetQuery'
  end

end