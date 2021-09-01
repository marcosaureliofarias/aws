module EasyCalendar
  module UserAllocationGanttControllerPatch

    def self.included(base)
      base.extend(ClassMethods)
      base.include(InstanceMethods)

      base.class_eval do

        alias_method_chain :user_preloads, :easy_calendar
        alias_method_chain :user_data_preloads, :easy_calendar

      end
    end

    module InstanceMethods

      def user_preloads_with_easy_calendar
        preloads = user_preloads_without_easy_calendar
        preloads << :easy_meetings
        preloads
      end

      def user_data_preloads_with_easy_calendar
        preloads = user_preloads_without_easy_calendar
        preloads << :easy_meetings
        preloads
      end

    end

    module ClassMethods

    end

  end

end
EasyExtensions::PatchManager.register_controller_patch 'UserAllocationGanttController', 'EasyCalendar::UserAllocationGanttControllerPatch', :if => Proc.new{ Redmine::Plugin.installed?(:easy_user_allocations) }
