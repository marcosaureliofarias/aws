module EasyHelpdesk
  module UserPatch

    def self.included(base)
      # base.extend(ClassMethods)
      # base.send(:include, InstanceMethods)

      base.class_eval do
        has_many :easy_sla_events
        has_many :helpdesk_tickets, class_name: 'Issue', foreign_key: :easy_helpdesk_ticket_owner_id


        def hide_sla_data?
          return false if admin?

          pref.hide_sla_data || easy_user_type_for?(:hide_sla_data)
        end
      end
    end

    module InstanceMethods
    end

    module ClassMethods
    end

  end

end
RedmineExtensions::PatchManager.register_model_patch 'User', 'EasyHelpdesk::UserPatch'
