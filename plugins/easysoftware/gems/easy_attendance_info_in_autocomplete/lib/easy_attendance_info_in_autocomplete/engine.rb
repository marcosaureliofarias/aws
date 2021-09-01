require 'rys'

module EasyAttendanceInfoInAutocomplete
  class Engine < ::Rails::Engine
    include Rys::EngineExtensions
  
    rys_id 'easy_attendance_info_in_autocomplete'
  
    initializer 'easy_attendance_info_in_autocomplete.setup' do
      # Custom initializer
      if Redmine::Plugin.installed?(:easy_attendances)
        ActionController::Base.send :include, EasyAttendancesHelper
        ActionController::Base.send :helper, :easy_attendances
      end
    end
  end
end
