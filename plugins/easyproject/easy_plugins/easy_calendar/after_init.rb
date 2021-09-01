lib_dir = File.join(File.dirname(__FILE__), 'lib', 'easy_calendar')

EpmEasyCalendar.register_to_scope(:user, :plugin => :easy_calendar)
EpmEasyCalendar.register_to_page('easy-calendar-module', :plugin => :easy_calendar)
EpmProjectMeetings.register_to_scope(:project, :plugin => :easy_calendar)

EasyExtensions::PatchManager.register_easy_page_controller 'EasyCalendarController'

Dir[File.dirname(__FILE__) + '/test/mailers/previews/*.rb'].each { |file| require_dependency file } if Rails.env.development?

EasyExtensions::AfterInstallScripts.add do
  page = EasyPage.where(:page_name => 'easy-calendar-module').first
  page_template = page.default_template

  unless page_template
    page_template = EasyPageTemplate.create(:easy_pages_id => page.id, :template_name => 'Default template', :description => 'Default template', :is_default => true)

    EasyPageTemplateModule.create_template_module(page, page_template, EpmEasyCalendar.first, 'top-middle', HashWithIndifferentAccess.new(:enabled_calendars => ['easy_meeting_calendar'], :display_from => '09:00', :display_to => '20:00', :user_ids => [], :default_view => 'agendaWeek'), 1)
  end

  EasyPageZoneModule.create_from_page_template(page_template) if !page.all_modules.exists?
end

ActiveSupport.on_load(:easyproject, yield: true) do

  require 'easy_calendar/hooks'
  require 'easy_calendar/menus'
  require 'easy_calendar/proposer'
  require 'easy_calendar/internals'
  require 'easy_calendar/permissions'
  require 'easy_calendar/big_recurring_job'
  require 'easy_calendar/icalendar_import_service'

end

RedmineExtensions::Reloader.to_prepare do

  EasySetting.map.boolean_keys(:easy_caldav_enabled)

  require 'easy_calendar/advanced_calendar'
  Dir[File.dirname(__FILE__) + '/lib/easy_calendar/advanced_calendars/*.rb'].each {|file| require file}
  require 'easy_calendar/easy_calendar_events/easy_calendar_event'
  require 'easy_calendar/easy_calendar_events/easy_meeting_calendar_event'
  require 'easy_calendar/easy_calendar_events/easy_attendances/easy_attendance_calendar_event' if Redmine::Plugin.installed?(:easy_attendances)
  require 'easy_calendar/easy_calendar_events/easy_entity_activity_calendar_event' if Redmine::Plugin.installed?(:easy_crm) && Redmine::Plugin.installed?(:easy_contacts)
  require 'easy_calendar/easy_calendar_events/easy_icalendar_event_calendar_event'

  EasyExtensions::EntityRepeater.map do |repeater|
    repeater.register 'EasyMeeting'
  end

end
