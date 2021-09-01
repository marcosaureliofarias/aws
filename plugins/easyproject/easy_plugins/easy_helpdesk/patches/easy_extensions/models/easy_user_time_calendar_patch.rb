module EasyHelpdesk
  module EasyUserTimeCalendarPatch
    def self.included(base)
      base.class_eval do
        def easy_helpdesk_sla_non_working_day?(day)
          self.weekend?(day) || self.holiday?(day) || self.exception?(day)
        end
      end
    end
  end
end
EasyExtensions::PatchManager.register_model_patch 'EasyUserTimeCalendar', 'EasyHelpdesk::EasyUserTimeCalendarPatch'
