module EasyHelpdesk
  module TimeEntryPatch

    def self.included(base)

      base.class_eval do

        belongs_to :easy_helpdesk_project, :foreign_key => 'project_id', :primary_key => 'project_id'
        
      end
    end

  end
end
EasyExtensions::PatchManager.register_model_patch 'TimeEntry', 'EasyHelpdesk::TimeEntryPatch'
