module EasyCalendar
  module ApplicationHelperPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        def options_for_select_external_calendars(user = User.current)
          options_from_collection_for_select(user.easy_icalendars, :id, :name) +
          content_tag(:option, l(:label_add_external_calendar), value: '')
        end

        def easy_meeting_page_url(easy_meeting: , external: false)
          if external
            nil
          else
            easy_meeting_url(easy_meeting)
          end
        end

      end
    end

    module InstanceMethods
    end

  end
end
EasyExtensions::PatchManager.register_helper_patch 'ApplicationHelper', 'EasyCalendar::ApplicationHelperPatch'
