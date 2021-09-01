module EasyHelpdesk
  module TrackerPatch

    def self.included(base)
      base.include(InstanceMethods)
      base.class_eval do
        old_core_fields = Tracker::CORE_FIELDS
        remove_const('CORE_FIELDS')
        const_set('CORE_FIELDS', (old_core_fields + ['easy_helpdesk_ticket_owner_id']).freeze)
        remove_const('CORE_FIELDS_ALL')
        const_set('CORE_FIELDS_ALL', (Tracker::CORE_FIELDS_UNDISABLABLE + Tracker::CORE_FIELDS).freeze)

        alias_method_chain :disabled_core_fields, :easy_helpdesk

      end
    end

    module InstanceMethods
      def disabled_core_fields_with_easy_helpdesk
        fields = disabled_core_fields_without_easy_helpdesk
        if new_record?
          fields |= ['easy_helpdesk_ticket_owner_id']
        end
        fields
      end
    end
  end
end
EasyExtensions::PatchManager.register_model_patch 'Tracker', 'EasyHelpdesk::TrackerPatch'
