module EasyHelpdesk
  module ProjectPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        has_one :easy_helpdesk_project, :dependent => :destroy
        has_many :easy_sla_events, dependent: :destroy
        delegate :monthly_hours, :remaining_hours, :spent_time_current_month, :spent_time_last_month, :easy_helpdesk_total_spent_time, :to => :easy_helpdesk_project, :prefix => true, :allow_nil => true

      end
    end

    module InstanceMethods

    end

  end

end
EasyExtensions::PatchManager.register_model_patch 'Project', 'EasyHelpdesk::ProjectPatch'
