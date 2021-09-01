module EasyGanttResources
  module EasyMeetingPatch

    def self.included(base)
      base.class_eval do
        definition = safe_attributes.find{|(names, _)| names.include?('name') }
        if_proc = definition && definition.second[:if]

        safe_attributes 'easy_resource_dont_allocate', if: if_proc
      end
    end

  end
end
RedmineExtensions::PatchManager.register_model_patch 'EasyMeeting', 'EasyGanttResources::EasyMeetingPatch', if: proc { Redmine::Plugin.installed?(:easy_calendar) }
